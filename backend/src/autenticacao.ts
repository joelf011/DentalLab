import type { FastifyReply, FastifyRequest } from 'fastify';
import { bd } from './db.ts';

// Proteção das rotas com login.
//
// Como se usa numa rota:
//   app.get('/api/...', { preHandler: exigirLogin }, async (request) => { ... });
//   app.post('/api/...', { preHandler: exigirCargo('Administrador') }, async (request) => { ... });
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

// Diz ao TypeScript o que está dentro do token, para request.user.cargo (etc.) funcionar sem erros.
declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: UtilizadorLogin;
    user: UtilizadorLogin;
  }
}

// Verifica a sessão de um pedido. Usada pelo exigirLogin e pelo exigirCargo.
//  1. Verifica o token do cabeçalho "Authorization: Bearer <token>" (se falta, é falso ou expirou: 401).
//  2. Confirma na BD que a conta continua ativa (se o Administrador a desativou: 401).
//  3. Põe em request.user os dados ATUAIS da BD: se o cargo mudou depois do login, conta o novo.
// Devolve true se a sessão é válida; se não for, já respondeu 401 e devolve false.
async function verificarSessao(request: FastifyRequest, reply: FastifyReply): Promise<boolean> {
  try {
    await request.jwtVerify();
  } catch {
    reply.code(401).send({ erro: 'Sessão inválida ou expirada. Inicie sessão outra vez.' });
    return false;
  }

  const resultado = await bd.query(
    'SELECT id, nome, cargo, cliente_id FROM vw_utilizador WHERE id = $1 AND ativo',
    [request.user.id],
  );
  const utilizador = resultado.rows[0];
  if (!utilizador) {
    reply.code(401).send({ erro: 'Esta conta já não está ativa.' });
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
      return reply.code(403).send({ erro: 'Não tem permissão para fazer isto.' });
    }
  };
}
