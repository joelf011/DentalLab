import type { FastifyInstance } from 'fastify';
import { bd } from '../../comum/bd.ts';

// Estado da API.
export async function rotasSaude(app: FastifyInstance) {
  // GET /api/v1/health: confirma que a API está a funcionar e que consegue falar com a BD.
  app.get('/health', async (request, reply) => {
    try {
      await bd.query('SELECT 1');
      return { api: 'ok', bd: 'ok' };
    } catch (erro) {
      request.log.error(erro);
      return reply.code(503).send({ api: 'ok', bd: 'sem ligação' });
    }
  });
}
