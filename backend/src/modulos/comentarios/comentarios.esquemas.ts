import { paramId, resposta, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas dos comentários (ver comum/esquemas.ts)

const etiqueta = ['Comunicação'];

// Um comentário, tal como vem da vista vw_comentario.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'Comentario#' }.
export const esquemaComentario = {
  $id: 'Comentario',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    ordem_trabalho_id: { type: ['integer', 'null'], description: 'Comentário da ordem: a clínica vê-o.' },
    trabalho_id: { type: ['integer', 'null'], description: 'Nota interna de um trabalho: só o laboratório a vê.' },
    utilizador_id: { type: 'integer' },
    autor: { type: 'string' },
    cargo_autor: { type: 'string', description: 'Administrador, Colaborador ou Cliente.' },
    conteudo: { type: 'string' },
    data_criacao: { type: 'string', format: 'date-time' },
    data_edicao: { type: ['string', 'null'], format: 'date-time' },
  },
  required: ['id', 'ordem_trabalho_id', 'trabalho_id', 'utilizador_id', 'autor', 'cargo_autor', 'conteudo', 'data_criacao', 'data_edicao'],
};

// O que se envia para escrever
const corpoComentario = {
  type: 'object',
  properties: {
    conteudo: { type: 'string', minLength: 1, maxLength: 5000 },
  },
  required: ['conteudo'],
  additionalProperties: false,
};

// 201: o comentário criado (não tem endereço próprio, por isso não há Location; como em AI3)
const comentarioCriado = resposta('Criado. Devolve o comentário.', { $ref: 'Comentario#' }, 'no-store');

// GET /api/v1/ordens/:id/comentarios
export const listarComentariosOrdem = {
  tags: etiqueta,
  operationId: 'listarComentariosOrdem',
  summary: 'Mensagens de uma ordem',
  description: 'A conversa entre a clínica e o laboratório sobre a ordem, da mais antiga para a mais recente. A clínica só vê as das suas ordens.',
  params: paramId,
  response: {
    200: resposta('As mensagens.', { type: 'array', items: { $ref: 'Comentario#' } }),
    ...respostasErro(400, 401, 404),
  },
};

// POST /api/v1/ordens/:id/comentarios
export const criarComentarioOrdem = {
  tags: etiqueta,
  operationId: 'criarComentarioOrdem',
  summary: 'Escrever uma mensagem numa ordem',
  description: 'A clínica (nas suas ordens) ou o laboratório. A outra parte vê-a.',
  params: paramId,
  body: corpoComentario,
  response: {
    201: comentarioCriado,
    ...respostasErro(400, 401, 404),
  },
};

// GET /api/v1/trabalhos/:id/notas
export const listarNotasTrabalho = {
  tags: etiqueta,
  operationId: 'listarNotasTrabalho',
  summary: 'Notas internas de um trabalho',
  description: 'Só o laboratório (a clínica não as vê). Da mais antiga para a mais recente.',
  params: paramId,
  response: {
    200: resposta('As notas.', { type: 'array', items: { $ref: 'Comentario#' } }),
    ...respostasErro(400, 401, 403, 404),
  },
};

// POST /api/v1/trabalhos/:id/notas
export const criarNotaTrabalho = {
  tags: etiqueta,
  operationId: 'criarNotaTrabalho',
  summary: 'Escrever uma nota interna num trabalho',
  description: 'Só o laboratório. A clínica não a vê; para falar com a clínica usa-se POST /ordens/:id/comentarios.',
  params: paramId,
  body: corpoComentario,
  response: {
    201: comentarioCriado,
    ...respostasErro(400, 401, 403, 404),
  },
};
