import type { FastifyInstance } from 'fastify';
import { bd } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';

// Estado da API.
export async function rotasSaude(app: FastifyInstance) {
  // GET /api/v1/saude: confirma que a API está a funcionar e que consegue falar com a BD.
  app.get('/saude', async (request, reply) => {
    try {
      await bd.query('SELECT 1');
      return { api: 'ok', bd: 'ok' };
    } catch (erro) {
      request.log.error(erro);
      return enviarErro(reply, 503, 'A API está a funcionar, mas não consegue ligar-se à base de dados.');
    }
  });
}
