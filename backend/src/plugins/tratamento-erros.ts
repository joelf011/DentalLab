import type { FastifyError, FastifyInstance } from 'fastify';
import { mensagemErroDados } from '../comum/erros.ts';

// Respostas de erro de toda a API.
// Todas têm o mesmo formato: { "erro": "mensagem" }
export function registarTratamentoErros(app: FastifyInstance) {
  // Quando uma rota dá erro, vem parar aqui.
  app.setErrorHandler((erro: FastifyError, request, reply) => {
    // Erro nos dados enviados: RAISE EXCEPTION das funções, regras das tabelas, formato errado...
    // A mensagem para o utilizador vem de comum/erros.ts.
    const mensagem = mensagemErroDados(erro);
    if (mensagem !== null) {
      return reply.code(400).send({ erro: mensagem });
    }
    // Outros erros do próprio Fastify com código conhecido (ex.: pedido demasiado grande).
    if (erro.statusCode !== undefined && erro.statusCode < 500) {
      return reply.code(erro.statusCode).send({ erro: erro.message });
    }
    // Qualquer outro erro fica registado no terminal; quem fez o pedido recebe uma mensagem genérica.
    request.log.error(erro);
    return reply.code(500).send({ erro: 'Ocorreu um erro inesperado.' });
  });

  // Pedido para uma rota que não existe.
  app.setNotFoundHandler((_request, reply) => {
    return reply.code(404).send({ erro: 'Esta rota não existe.' });
  });
}
