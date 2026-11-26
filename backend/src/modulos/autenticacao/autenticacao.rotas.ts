import bcrypt from 'bcryptjs';
import type { FastifyInstance, FastifyReply } from 'fastify';
import { randomUUID } from 'node:crypto';
import { enviarSemSessao, exigirLogin, type UtilizadorLogin } from '../../comum/acesso.ts';
import { bd } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { PREFIXO_API } from '../../comum/respostas.ts';
import { configuracao } from '../../configuracao.ts';
import { COOKIE_SESSAO } from '../../plugins/jwt.ts';
import {
  criarSessao,
  criarToken,
  esquemaUtilizadorLigado,
  obterSessao,
  terminarSessao,
} from './autenticacao.esquemas.ts';

// Rotas da autenticação. Há duas formas de entrar, como em AI3:
// - app (Flutter): POST /tokens devolve o token, que a app guarda e envia em "Authorization: Bearer <token>";
// - site (React): POST /sessao guarda o token num cookie HttpOnly, que o navegador envia sozinho.
// GET /sessao serve às duas (cookie ou token); DELETE /sessao apaga o cookie do site.
// Os dados vêm da função fn_utilizador_login (a única que lê o password_hash) e da vista vw_utilizador.

// O que se envia para entrar
interface Credenciais {
  email: string;
  password: string;
}

// Quem está ligado (resposta do login e de GET /sessao)
interface UtilizadorLigado extends UtilizadorLogin {
  email: string;
  password_temporaria: boolean; // se for true, o frontend obriga a mudar a palavra-passe antes de continuar
}

// Hash de uma palavra-passe aleatória (ninguém a conhece), com o mesmo custo dos verdadeiros.
// Calcula-se uma vez, quando a API arranca. Usa-se quando o email não existe (ver confirmarCredenciais).
const HASH_FICTICIO = bcrypt.hashSync(randomUUID(), configuracao.bcrypt.custo);

// Como o cookie da sessão é guardado no navegador:
// - httpOnly: o JavaScript da página não o consegue ler (um script malicioso não rouba a sessão);
// - sameSite 'strict': o navegador só o envia em pedidos feitos a partir do próprio site (protege de CSRF);
// - secure 'auto': só por HTTPS quando a API estiver em HTTPS (em localhost é HTTP);
// - path: só é enviado para os endereços da API;
// - maxAge: dura o mesmo que o token (em segundos).
const opcoesCookie = {
  path: PREFIXO_API,
  httpOnly: true,
  sameSite: 'strict',
  secure: 'auto',
  maxAge: configuracao.jwt.validade,
} as const;

// Confirma o email e a palavra-passe. Usada por POST /tokens (app) e POST /sessao (site).
// Devolve quem entrou; se as credenciais não servirem, já respondeu (401 ou 403) e devolve null.
async function confirmarCredenciais(dados: Credenciais, reply: FastifyReply): Promise<UtilizadorLigado | null> {
  const resultado = await bd.query('SELECT * FROM fn_utilizador_login($1)', [dados.email]);
  const utilizador = resultado.rows[0];

  // Email que não existe ou palavra-passe errada: a mesma resposta nos dois casos, para não revelar que emails têm conta.
  // A resposta também tem de demorar o mesmo: o bcrypt é lento de propósito (cerca de 0,2 s) e, se só corresse
  // quando o email existe, bastava medir o tempo para o descobrir. Por isso, sem conta, compara-se com o HASH_FICTICIO
  // (o resultado não conta: sem conta, a resposta é sempre 401).
  const hash = utilizador ? utilizador.password_hash : HASH_FICTICIO;
  const passwordCerta = await bcrypt.compare(dados.password, hash);
  if (!utilizador || !passwordCerta) {
    enviarErro(reply, 401, 'Email ou palavra-passe incorretos.');
    return null;
  }
  if (!utilizador.ativo) {
    enviarErro(reply, 403, 'Esta conta está desativada. Contacte o laboratório.');
    return null;
  }
  if (!utilizador.aprovado) {
    enviarErro(reply, 403, 'A sua conta ainda não foi aprovada pelo laboratório.');
    return null;
  }

  return {
    id: utilizador.id,
    nome: utilizador.nome,
    cargo: utilizador.cargo,
    cliente_id: utilizador.cliente_id,
    email: utilizador.email,
    password_temporaria: utilizador.password_temporaria,
  };
}

// Cria o token de quem entrou. Só leva o que as rotas protegidas precisam (aparece em request.user).
function criarTokenDe(app: FastifyInstance, utilizador: UtilizadorLigado) {
  const dadosToken: UtilizadorLogin = {
    id: utilizador.id,
    nome: utilizador.nome,
    cargo: utilizador.cargo,
    cliente_id: utilizador.cliente_id,
  };
  return app.jwt.sign(dadosToken);
}

export async function rotasAutenticacao(app: FastifyInstance) {
  // Esquema com nome, usado pelas respostas do login e de GET /sessao
  app.addSchema(esquemaUtilizadorLigado);

  // POST /api/v1/tokens com { "email": "...", "password": "..." }: a app entra
  // Devolve o token (para enviar nos pedidos seguintes) e quem entrou.
  app.post('/tokens', { schema: criarToken }, async (request, reply) => {
    const utilizador = await confirmarCredenciais(request.body as Credenciais, reply);
    if (!utilizador) {
      return reply; // já respondeu 401 ou 403
    }
    return { token: criarTokenDe(app, utilizador), utilizador };
  });

  // POST /api/v1/sessao com { "email": "...", "password": "..." }: o site entra
  // O token vai no cookie (Set-Cookie), não no corpo: o JavaScript do site nunca o vê.
  app.post('/sessao', { schema: criarSessao }, async (request, reply) => {
    const utilizador = await confirmarCredenciais(request.body as Credenciais, reply);
    if (!utilizador) {
      return reply; // já respondeu 401 ou 403, sem cookie
    }
    reply.setCookie(COOKIE_SESSAO, criarTokenDe(app, utilizador), opcoesCookie);
    return utilizador;
  });

  // GET /api/v1/sessao: quem está ligado (com os dados atuais da BD)
  // Serve ao site (cookie) e à app (token): ao abrir, para saber se a sessão continua.
  app.get('/sessao', { schema: obterSessao, preHandler: exigirLogin }, async (request, reply) => {
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
      cliente_id: utilizador.cliente_id,
      email: utilizador.email,
      password_temporaria: utilizador.password_temporaria,
    };
  });

  // DELETE /api/v1/sessao: o site sai
  // Só pede ao navegador que apague o cookie (com o mesmo path com que foi criado). O token não é revogado:
  // quem o tivesse copiado podia usá-lo até expirar, mas como é HttpOnly, nem o JavaScript da página o lê.
  // Na app, sair é apagar o token guardado no telemóvel.
  app.delete('/sessao', { schema: terminarSessao }, async (_request, reply) => {
    reply.clearCookie(COOKIE_SESSAO, { path: PREFIXO_API });
    return reply.code(204).send();
  });
}
