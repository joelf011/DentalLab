import type { FastifyInstance } from 'fastify';

// Cabeçalho Cache-Control em todas as respostas (regra de AI3).
// Diz ao navegador (e ao service worker do site) se pode guardar a resposta e reutilizá-la:
//   - private, no-cache → leituras de quem tem login: só o próprio navegador pode guardar a resposta,
//                         e tem de confirmar com a API antes de a reutilizar;
//   - no-store          → escritas, login e todos os erros: nunca se guardam;
//   - public, max-age=… → dados públicos, iguais para todos: a própria rota define-o.
// Uma rota pode escolher outro valor com reply.header('Cache-Control', ...); aqui só se põe quando falta.
export function registarCache(app: FastifyInstance) {
  app.addHook('onSend', async (request, reply, corpo) => {
    if (!reply.hasHeader('Cache-Control')) {
      const leitura = request.method === 'GET' || request.method === 'HEAD';
      const sucesso = reply.statusCode < 400;
      reply.header('Cache-Control', leitura && sucesso ? 'private, no-cache' : 'no-store');
    }
    return corpo;
  });
}
