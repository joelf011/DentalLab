import type { FastifyReply, FastifyRequest } from 'fastify';

// Proteção das rotas com login.
//
// Como se usa numa rota:
//   app.get('/api/...', { preHandler: exigirLogin }, async (request) => { ... });
//   app.post('/api/...', { preHandler: exigirCargo('Administrador') }, async (request) => { ... });
//
// Dentro de uma rota protegida, request.user é quem fez login:
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

// Só deixa passar quem tem login.
// Verifica o token do cabeçalho "Authorization: Bearer <token>"; se faltar, for falso ou tiver expirado, responde 401.
export async function exigirLogin(request: FastifyRequest, reply: FastifyReply) {
  try {
    await request.jwtVerify();
  } catch {
    return reply.code(401).send({ erro: 'Sessão inválida ou expirada. Inicie sessão outra vez.' });
  }
}

// Só deixa passar quem tem login E um dos cargos indicados.
// Ex.: exigirCargo('Administrador') ou exigirCargo('Administrador', 'Colaborador')
export function exigirCargo(...cargos: Cargo[]) {
  return async function (request: FastifyRequest, reply: FastifyReply) {
    try {
      await request.jwtVerify();
    } catch {
      return reply.code(401).send({ erro: 'Sessão inválida ou expirada. Inicie sessão outra vez.' });
    }
    if (!cargos.includes(request.user.cargo)) {
      return reply.code(403).send({ erro: 'Não tem permissão para fazer isto.' });
    }
  };
}
