import type { FastifyReply, FastifyRequest } from 'fastify';
import { bd } from './bd.ts';
import { enviarErro } from './erros.ts';

// Controlo de acesso às rotas: quem tem login (exigirLogin) e que cargos podem usar cada rota (exigirCargo).
//
// Como se usa numa rota:
//   app.get('/...', { preHandler: exigirLogin }, async (request) => { ... });
//   app.post('/...', { preHandler: exigirCargo('Administrador') }, async (request) => { ... });
//
// Dentro de uma rota protegida, request.user é quem fez login, com os dados atuais da BD:
//   request.user.id, request.user.nome, request.user.cargo, request.user.cliente_id

export type Cargo = 'Administrador' | 'Colaborador' | 'Cliente';

// O que vai dentro do token de login (e que depois aparece em request.user)
export interface UtilizadorLogin {
  id: number;
  nome: string;
  cargo: Cargo;
  cliente_id: number | null; // só o cargo Cliente tem clínica; nos outros é null
}

// O que vai dentro do link de recuperação da palavra-passe (modulos/conta)
export interface DadosRecuperacao {
  id: number;
  impressao: string; // resumo do hash atual da palavra-passe: quando ela muda, o link deixa de servir
}

// Diz ao TypeScript o que está dentro dos tokens, para request.user.cargo (etc.) funcionar sem erros.
// O token do login leva UtilizadorLogin; o do link de recuperação leva DadosRecuperacao (com outro segredo).
declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: UtilizadorLogin | DadosRecuperacao;
    user: UtilizadorLogin;
  }
}

// Resposta 401: o pedido não tem sessão, ou a sessão já não serve.
// O cabeçalho WWW-Authenticate diz ao cliente como se autenticar (regra de AI3):
//   - Bearer                        → não veio nenhum token;
//   - Bearer error="invalid_token"  → veio um token, mas é falso, expirou, ou a conta foi desativada.
export function enviarSemSessao(reply: FastifyReply, mensagem: string, tokenInvalido: boolean) {
  reply.header('WWW-Authenticate', tokenInvalido ? 'Bearer error="invalid_token"' : 'Bearer');
  return enviarErro(reply, 401, mensagem);
}

// Verifica a sessão de um pedido. Usada pelo exigirLogin e pelo exigirCargo.
//  1. Verifica o token: do cabeçalho "Authorization: Bearer <token>" (app) ou do cookie "sessao" (site).
//     Se falta, é falso ou expirou: 401.
//  2. Confirma na BD que a conta continua ativa (se o Administrador a desativou: 401).
//  3. Põe em request.user os dados ATUAIS da BD: se o cargo mudou depois do login, conta o novo.
// Devolve true se a sessão é válida; se não for, já respondeu 401 e devolve false.
async function verificarSessao(request: FastifyRequest, reply: FastifyReply): Promise<boolean> {
  try {
    await request.jwtVerify();
  } catch (erro) {
    // O @fastify/jwt diz porque falhou: ou não veio token (nem no cabeçalho, nem no cookie),
    // ou o token não serve (falso, expirado...).
    const semToken = (erro as { code?: string }).code === 'FST_JWT_NO_AUTHORIZATION_IN_COOKIE';
    if (semToken) {
      enviarSemSessao(reply, 'Tem de iniciar sessão.', false);
    } else {
      enviarSemSessao(reply, 'Sessão inválida ou expirada. Inicie sessão outra vez.', true);
    }
    return false;
  }

  const resultado = await bd.query(
    'SELECT id, nome, cargo, cliente_id FROM vw_utilizador WHERE id = $1 AND ativo',
    [request.user.id],
  );
  const utilizador = resultado.rows[0];
  if (!utilizador) {
    enviarSemSessao(reply, 'Esta conta já não está ativa.', true);
    return false;
  }

  request.user = {
    id: utilizador.id,
    nome: utilizador.nome,
    cargo: utilizador.cargo,
    cliente_id: utilizador.cliente_id,
  };
  return true;
}

// Só deixa passar quem tem login (e uma conta ativa).
export async function exigirLogin(request: FastifyRequest, reply: FastifyReply) {
  if (!(await verificarSessao(request, reply))) {
    return reply; // já respondeu 401: a rota não chega a correr
  }
}

// Só deixa passar quem tem login E um dos cargos indicados.
// Ex.: exigirCargo('Administrador') ou exigirCargo('Administrador', 'Colaborador')
export function exigirCargo(...cargos: Cargo[]) {
  return async function (request: FastifyRequest, reply: FastifyReply) {
    if (!(await verificarSessao(request, reply))) {
      return reply; // já respondeu 401: a rota não chega a correr
    }
    if (!cargos.includes(request.user.cargo)) {
      return enviarErro(reply, 403, 'Não tem permissão para fazer isto.');
    }
  };
}

// A ordem existe e quem pede pode vê-la? A clínica só vê as suas; o laboratório vê todas.
// Usada nas rotas que dependem de uma ordem (comentários, ficheiros): se der false, responde-se 404.
export async function podeVerOrdem(utilizador: UtilizadorLogin, ordemId: number): Promise<boolean> {
  const resultado = await bd.query('SELECT cliente_id FROM vw_ordem_trabalho WHERE id = $1', [ordemId]);
  const ordem = resultado.rows[0];
  if (!ordem) {
    return false;
  }
  return utilizador.cargo !== 'Cliente' || ordem.cliente_id === utilizador.cliente_id;
}
