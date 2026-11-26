import type { FastifyInstance } from 'fastify';
import { exigirLogin } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { listarNotificacoes, marcarNotificacaoLida, marcarTodasLidas } from './notificacoes.esquemas.ts';

// Rotas das notificações de quem está ligado (o sino, no site e na app).
// As notificações são criadas pelos triggers da BD; aqui só se leem e se marcam como lidas.
// Ler: vista vw_notificacao. Marcar como lidas: pr_marcar_notificacoes_lidas.

export async function rotasNotificacoes(app: FastifyInstance) {
  // GET /api/v1/notificacoes: as minhas notificações (no máximo as 100 mais recentes)
  // GET /api/v1/notificacoes?por_ler=true: só as que ainda não li
  app.get('/notificacoes', { schema: listarNotificacoes, preHandler: exigirLogin }, async (request) => {
    const { por_ler } = request.query as { por_ler?: boolean };
    const resultado = await bd.query(
      `SELECT * FROM vw_notificacao
       WHERE utilizador_id = $1 AND (NOT $2 OR NOT lida)
       ORDER BY data_criacao DESC
       LIMIT 100`,
      [request.user.id, por_ler === true],
    );
    return resultado.rows;
  });

  // POST /api/v1/notificacoes/1/lida: marca uma notificação como lida (só as próprias)
  app.post('/notificacoes/:id/lida', { schema: marcarNotificacaoLida, preHandler: exigirLogin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const minha = await bd.query('SELECT id FROM vw_notificacao WHERE id = $1 AND utilizador_id = $2', [id, request.user.id]);
    if (minha.rows.length === 0) {
      return enviarErro(reply, 404, 'A notificação não existe.');
    }
    await escreverComo(request.user.id, 'CALL pr_marcar_notificacoes_lidas($1, $2)', [request.user.id, id]);
    return reply.code(204).send();
  });

  // POST /api/v1/notificacoes/lidas: marca todas as minhas notificações como lidas
  app.post('/notificacoes/lidas', { schema: marcarTodasLidas, preHandler: exigirLogin }, async (request, reply) => {
    await escreverComo(request.user.id, 'CALL pr_marcar_notificacoes_lidas($1)', [request.user.id]);
    return reply.code(204).send();
  });
}
