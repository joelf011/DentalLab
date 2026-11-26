import type { FastifyError, FastifyInstance } from 'fastify';
import { enviarErro, esquemaErro, traduzirErro, traduzirValidacao } from '../comum/erros.ts';

// Respostas de erro de toda a API, no formato de comum/erros.ts: { codigo, mensagem, detalhes }
export function registarTratamentoErros(app: FastifyInstance) {
  // O esquema do formato de erro, usado pelas rotas com { $ref: 'Erro#' } (ver comum/esquemas.ts)
  app.addSchema(esquemaErro);

  // Quando uma rota dá erro (e não respondeu ela própria), vem parar aqui.
  app.setErrorHandler((erro: FastifyError, request, reply) => {
    // Pedido que não cumpre o esquema da rota (plugins/validacao.ts): 400 com a lista dos problemas.
    if (erro.validation) {
      const mensagem =
        erro.validationContext === 'body' ? 'Os dados enviados não são válidos.' : 'O endereço do pedido tem valores inválidos.';
      return enviarErro(reply, 400, mensagem, traduzirValidacao(erro.validation));
    }
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
