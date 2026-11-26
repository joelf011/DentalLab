import type { FastifyInstance } from 'fastify';
import { bd } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { verificarSaude } from './saude.esquemas.ts';

// Estado da API.
export async function rotasSaude(app: FastifyInstance) {
  // GET /api/v1/saude: confirma que a API está a funcionar e que consegue falar com a BD.
  app.get('/saude', { schema: verificarSaude }, async (request, reply) => {
    // O estado tem de ser sempre o atual, por isso nunca se guarda em cache.
    reply.header('Cache-Control', 'no-store');
    try {
      await bd.query('SELECT 1');
      return { api: 'ok', bd: 'ok' };
    } catch (erro) {
      request.log.error(erro);
      return enviarErro(reply, 503, 'A API está a funcionar, mas não consegue ligar-se à base de dados.');
    }
  });
}
