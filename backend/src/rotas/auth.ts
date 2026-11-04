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
}
