import bcrypt from 'bcryptjs';
import type { FastifyInstance } from 'fastify';
import { exigirLogin, type UtilizadorLogin } from '../autenticacao.ts';
import { bd } from '../db.ts';

// Rotas do login.
// Os dados vêm da função fn_utilizador_login (a única que lê o password_hash) e da vista vw_utilizador.

// O que o frontend envia no login
interface DadosLogin {
  email?: string;
  password?: string;
}

// O que o frontend envia para mudar a palavra-passe
interface DadosPassword {
  password_atual?: string;
  password_nova?: string;
}

export async function rotasAuth(app: FastifyInstance) {
  // POST /api/auth/login com { "email": "...", "password": "..." }
  // Devolve o token (para enviar nos pedidos seguintes) e os dados do utilizador.
  app.post('/api/auth/login', async (request, reply) => {
    const dados = request.body as DadosLogin | undefined;
    if (!dados?.email || !dados?.password) {
      return reply.code(400).send({ erro: 'Indique o email e a palavra-passe.' });
    }

    const resultado = await bd.query('SELECT * FROM fn_utilizador_login($1)', [dados.email]);
    const utilizador = resultado.rows[0];

    // Email que não existe ou palavra-passe errada: a mesma mensagem nos dois casos,
    // para não revelar que emails têm conta.
    if (!utilizador || !(await bcrypt.compare(dados.password, utilizador.password_hash))) {
      return reply.code(401).send({ erro: 'Email ou palavra-passe incorretos.' });
    }
    if (!utilizador.ativo) {
      return reply.code(403).send({ erro: 'Esta conta está desativada. Contacte o laboratório.' });
    }
    if (!utilizador.aprovado) {
      return reply.code(403).send({ erro: 'A sua conta ainda não foi aprovada pelo laboratório.' });
    }

    // O que fica dentro do token (e depois em request.user, nas rotas protegidas)
    const dadosToken: UtilizadorLogin = {
      id: utilizador.id,
      nome: utilizador.nome,
      cargo: utilizador.cargo,
      cliente_id: utilizador.cliente_id,
    };

    return {
      token: app.jwt.sign(dadosToken),
      utilizador: {
        ...dadosToken,
        email: utilizador.email,
        // Se for true, o frontend deve obrigar a pessoa a mudar a palavra-passe antes de continuar.
        password_temporaria: utilizador.password_temporaria,
      },
    };
  });

  // GET /api/auth/eu: quem está ligado (com os dados atuais da BD)
  // O frontend chama esta rota ao abrir, para saber se o token guardado ainda serve.
  app.get('/api/auth/eu', { preHandler: exigirLogin }, async (request, reply) => {
    const resultado = await bd.query('SELECT * FROM vw_utilizador WHERE id = $1 AND ativo', [request.user.id]);
    const utilizador = resultado.rows[0];
    if (!utilizador) {
      return reply.code(401).send({ erro: 'Esta conta já não está ativa.' });
    }
    return {
      id: utilizador.id,
      nome: utilizador.nome,
      cargo: utilizador.cargo,
      cliente_id: request.user.cliente_id,
      email: utilizador.email,
      password_temporaria: utilizador.password_temporaria,
    };
  });

  // PUT /api/auth/password com { "password_atual": "...", "password_nova": "..." }
  // Muda a palavra-passe de quem está ligado e deixa de ser temporária.
  app.put('/api/auth/password', { preHandler: exigirLogin }, async (request, reply) => {
    const dados = request.body as DadosPassword | undefined;
    if (!dados?.password_atual || !dados?.password_nova) {
      return reply.code(400).send({ erro: 'Indique a palavra-passe atual e a nova.' });
    }
    // Estas regras ficam aqui porque a BD nunca recebe a palavra-passe, só o hash.
    if (dados.password_nova.length < 8) {
      return reply.code(400).send({ erro: 'A nova palavra-passe tem de ter pelo menos 8 caracteres.' });
    }
    if (dados.password_nova === dados.password_atual) {
      return reply.code(400).send({ erro: 'A nova palavra-passe tem de ser diferente da atual.' });
    }

    // Vai buscar o hash atual: primeiro o email (pelo id do token), depois as credenciais.
    const conta = await bd.query('SELECT email FROM vw_utilizador WHERE id = $1 AND ativo', [request.user.id]);
    if (conta.rows.length === 0) {
      return reply.code(401).send({ erro: 'Esta conta já não está ativa.' });
    }
    const credenciais = await bd.query('SELECT password_hash FROM fn_utilizador_login($1)', [conta.rows[0].email]);

    // 400 e não 401: o frontend trata o 401 como "sessão terminada", e aqui a sessão está boa.
    if (!(await bcrypt.compare(dados.password_atual, credenciais.rows[0].password_hash))) {
      return reply.code(400).send({ erro: 'A palavra-passe atual está errada.' });
    }

    // O 12 é o "custo" do bcrypt: quanto maior, mais lento é adivinhar a palavra-passe. É o mesmo do admin inicial.
    const novoHash = await bcrypt.hash(dados.password_nova, 12);
    const resultado = await bd.query(
      `SELECT fn_utilizador_crud(
         p_operacao            => 'UPDATE',
         p_id                  => $1,
         p_password_hash       => $2,
         p_password_temporaria => false
       ) AS id`,
      [request.user.id, novoHash],
    );
    return resultado.rows[0];
  });
}
