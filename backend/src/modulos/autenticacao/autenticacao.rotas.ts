import bcrypt from 'bcryptjs';
import type { FastifyInstance } from 'fastify';
import { randomUUID } from 'node:crypto';
import { enviarSemSessao, exigirLogin, type UtilizadorLogin } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import { configuracao } from '../../configuracao.ts';
import {
  esquemaUtilizadorLigado,
  fazerLogin,
  mudarPassword,
  obterUtilizadorLigado,
  registarClinica,
} from './autenticacao.esquemas.ts';

// Rotas do login e do registo de clínicas.
// Os dados vêm da função fn_utilizador_login (a única que lê o password_hash) e da vista vw_utilizador.

// O que o frontend envia em cada rota. As regras (obrigatório, tamanho, formato) estão em autenticacao.esquemas.ts:
// quando a rota corre, os dados já foram confirmados.

// Login
interface DadosLogin {
  email: string;
  password: string;
}

// Mudar a palavra-passe
interface DadosPassword {
  password_atual: string;
  password_nova: string;
}

// Registo de uma clínica
interface DadosRegisto {
  nome: string;
  nif: string;
  morada_faturacao?: string;
  telefone?: string;
  email: string; // é o email de contacto da clínica e o email de login
  password: string;
}

// Hash de uma palavra-passe aleatória (ninguém a conhece), com o mesmo custo dos verdadeiros.
// Calcula-se uma vez, quando a API arranca. O login usa-o quando o email não existe (ver o login).
const HASH_FICTICIO = bcrypt.hashSync(randomUUID(), configuracao.bcrypt.custo);

export async function rotasAutenticacao(app: FastifyInstance) {
  // Esquema com nome, usado pelas respostas do login e de GET /auth/eu
  app.addSchema(esquemaUtilizadorLigado);

  // POST /api/v1/auth/registo: uma clínica regista-se sozinha (rota pública, sem login)
  // Cria a clínica e a conta de acesso, que fica à espera de aprovação do Administrador.
  // Até ser aprovada, o login responde 403 "A sua conta ainda não foi aprovada pelo laboratório."
  app.post('/auth/registo', { schema: registarClinica }, async (request, reply) => {
    const dados = request.body as DadosRegisto;
    // A função na BD confirma o resto (NIF ou email repetidos...).
    const resultado = await escreverComo(
      null,
      `SELECT fn_registar_clinica(
         p_nome             => $1,
         p_nif              => $2,
         p_morada_faturacao => $3,
         p_telefone         => $4,
         p_email            => $5,
         p_password_hash    => $6
       ) AS id`,
      [
        dados.nome,
        dados.nif,
        dados.morada_faturacao,
        dados.telefone,
        dados.email,
        await bcrypt.hash(dados.password, configuracao.bcrypt.custo),
      ],
    );
    return enviarCriado(reply, 'clientes', resultado.rows[0].id);
  });

  // POST /api/v1/auth/login com { "email": "...", "password": "..." }
  // Devolve o token (para enviar nos pedidos seguintes) e os dados do utilizador.
  app.post('/auth/login', { schema: fazerLogin }, async (request, reply) => {
    const dados = request.body as DadosLogin;
    const resultado = await bd.query('SELECT * FROM fn_utilizador_login($1)', [dados.email]);
    const utilizador = resultado.rows[0];

    // Email que não existe ou palavra-passe errada: a mesma resposta nos dois casos, para não revelar que emails têm conta.
    // A resposta também tem de demorar o mesmo: o bcrypt é lento de propósito (cerca de 0,2 s) e, se só corresse
    // quando o email existe, bastava medir o tempo para o descobrir. Por isso, sem conta, compara-se com o HASH_FICTICIO
    // (o resultado não conta: sem conta, a resposta é sempre 401).
    const hash = utilizador ? utilizador.password_hash : HASH_FICTICIO;
    const passwordCerta = await bcrypt.compare(dados.password, hash);
    if (!utilizador || !passwordCerta) {
      return enviarErro(reply, 401, 'Email ou palavra-passe incorretos.');
    }
    if (!utilizador.ativo) {
      return enviarErro(reply, 403, 'Esta conta está desativada. Contacte o laboratório.');
    }
    if (!utilizador.aprovado) {
      return enviarErro(reply, 403, 'A sua conta ainda não foi aprovada pelo laboratório.');
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

  // GET /api/v1/auth/eu: quem está ligado (com os dados atuais da BD)
  // O frontend chama esta rota ao abrir, para saber se o token guardado ainda serve.
  app.get('/auth/eu', { schema: obterUtilizadorLigado, preHandler: exigirLogin }, async (request, reply) => {
    // A sessão nunca se guarda em cache: tem de dizer sempre quem está ligado neste momento.
    reply.header('Cache-Control', 'no-store');
    const resultado = await bd.query('SELECT * FROM vw_utilizador WHERE id = $1 AND ativo', [request.user.id]);
    const utilizador = resultado.rows[0];
    if (!utilizador) {
      return enviarSemSessao(reply, 'Esta conta já não está ativa.', true);
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

  // PUT /api/v1/auth/password com { "password_atual": "...", "password_nova": "..." }
  // Muda a palavra-passe de quem está ligado e deixa de ser temporária.
  app.put('/auth/password', { schema: mudarPassword, preHandler: exigirLogin }, async (request, reply) => {
    const dados = request.body as DadosPassword;
    // Uma regra que compara dois campos não cabe no esquema, por isso fica aqui.
    if (dados.password_nova === dados.password_atual) {
      return enviarErro(reply, 400, 'A nova palavra-passe tem de ser diferente da atual.');
    }

    // Vai buscar o hash atual: primeiro o email (pelo id do token), depois as credenciais.
    const conta = await bd.query('SELECT email FROM vw_utilizador WHERE id = $1 AND ativo', [request.user.id]);
    if (conta.rows.length === 0) {
      return enviarSemSessao(reply, 'Esta conta já não está ativa.', true);
    }
    const credenciais = await bd.query('SELECT password_hash FROM fn_utilizador_login($1)', [conta.rows[0].email]);

    // 400 e não 401: o frontend trata o 401 como "sessão terminada", e aqui a sessão está boa.
    if (!(await bcrypt.compare(dados.password_atual, credenciais.rows[0].password_hash))) {
      return enviarErro(reply, 400, 'A palavra-passe atual está errada.');
    }

    const novoHash = await bcrypt.hash(dados.password_nova, configuracao.bcrypt.custo);
    const resultado = await escreverComo(
      request.user.id,
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
