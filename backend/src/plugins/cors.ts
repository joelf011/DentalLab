import fastifyCors from '@fastify/cors';
import type { FastifyInstance } from 'fastify';
import { configuracao } from '../configuracao.ts';

// CORS: autoriza os sites React (CORS_ORIGENS no .env) a usar a API a partir do navegador.
// Sem isto, o navegador bloqueia os pedidos do React (localhost:5173) para a API (localhost:3000).
// A app Flutter não é um navegador, por isso não precisa disto.
export function registarCors(app: FastifyInstance) {
  app.register(fastifyCors, {
    origin: configuracao.corsOrigens,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    // Cabeçalhos da resposta que o JavaScript do site pode ler (o navegador esconde os outros):
    // o endereço do registo criado e o motivo de um 401.
    exposedHeaders: ['Location', 'WWW-Authenticate'],
  });
}
