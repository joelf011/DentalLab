import type { FastifyError, FastifyInstance } from 'fastify';
import { enviarErro, traduzirErro } from '../comum/erros.ts';

// Respostas de erro de toda a API, no formato de comum/erros.ts: { codigo, mensagem, detalhes }
export function registarTratamentoErros(app: FastifyInstance) {
  // Quando uma rota dá erro (e não respondeu ela própria), vem parar aqui.
  app.setErrorHandler((erro: FastifyError, request, reply) => {
    // Erros conhecidos: RAISE EXCEPTION das funções, regras das tabelas, formato errado, JSON mal escrito...
    const conhecido = traduzirErro(erro);
    if (conhecido !== null) {
      return enviarErro(reply, conhecido.codigo, conhecido.mensagem);
    }
    // Outros erros do Fastify com código conhecido (4xx): fica a mensagem do próprio Fastify.
    if (erro.statusCode !== undefined && erro.statusCode < 500) {
      return enviarErro(reply, erro.statusCode, erro.message);
    }
    // Qualquer outro erro fica registado no terminal; quem fez o pedido recebe uma mensagem genérica.
    request.log.error(erro);
    return enviarErro(reply, 500, 'Ocorreu um erro inesperado.');
  });

  // Pedido para uma rota que não existe.
  app.setNotFoundHandler((_request, reply) => {
    return enviarErro(reply, 404, 'Esta rota não existe.');
  });
}
