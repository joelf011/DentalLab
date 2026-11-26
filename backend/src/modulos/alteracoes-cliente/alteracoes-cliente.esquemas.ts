import { paramId, resposta, respostaCriado, respostaId, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas dos pedidos de alteração dos dados de uma clínica (ver comum/esquemas.ts)

const etiqueta = ['Alterações de cliente'];

const textoOuNulo = { type: ['string', 'null'] };
const estados = ['pendente', 'aprovado', 'rejeitado'];

// Um pedido de alteração, tal como vem da vista vw_alteracao_cliente.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'AlteracaoCliente#' }.
export const esquemaAlteracaoCliente = {
  $id: 'AlteracaoCliente',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    cliente_id: { type: 'integer' },
    pedido_por: { type: 'string', description: 'Nome de quem pediu.' },
    data_pedido: { type: 'string', format: 'date-time' },
    nome_atual: { type: 'string' },
    morada_faturacao_atual: textoOuNulo,
    email_atual: textoOuNulo,
    telefone_atual: textoOuNulo,
    nome: { ...textoOuNulo, description: 'Valor pedido; null = não muda.' },
    morada_faturacao: { ...textoOuNulo, description: 'Valor pedido; null = não muda.' },
    email: { ...textoOuNulo, description: 'Valor pedido; null = não muda.' },
    telefone: { ...textoOuNulo, description: 'Valor pedido; null = não muda.' },
    estado: { type: 'string', enum: estados },
    decidido_por: { ...textoOuNulo, description: 'Nome de quem decidiu.' },
    data_decisao: { type: ['string', 'null'], format: 'date-time' },
    motivo_rejeicao: textoOuNulo,
  },
  required: [
    'id', 'cliente_id', 'pedido_por', 'data_pedido',
    'nome_atual', 'morada_faturacao_atual', 'email_atual', 'telefone_atual',
    'nome', 'morada_faturacao', 'email', 'telefone',
    'estado', 'decidido_por', 'data_decisao', 'motivo_rejeicao',
  ],
};

// POST /api/v1/alteracoes-cliente
export const pedirAlteracaoCliente = {
  tags: etiqueta,
  operationId: 'pedirAlteracaoCliente',
  summary: 'Pedir para alterar os dados da clínica',
  description:
    'Só o cargo Cliente, para a sua clínica. Envia só os campos que mudam. ' +
    'Só pode haver um pedido à espera de aprovação de cada vez (senão, 409).',
  body: {
    type: 'object',
    properties: {
      nome: { type: 'string', minLength: 1, maxLength: 150 },
      morada_faturacao: { type: 'string', maxLength: 255 },
      email: { type: 'string', format: 'email', maxLength: 254 },
      telefone: { type: 'string', maxLength: 20 },
    },
    minProperties: 1,
    additionalProperties: false,
  },
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403, 409),
  },
};

// GET /api/v1/alteracoes-cliente
export const listarAlteracoesCliente = {
  tags: etiqueta,
  operationId: 'listarAlteracoesCliente',
  summary: 'Listar os pedidos de alteração',
  description: 'O Administrador vê todos; uma clínica só os seus. Os mais recentes primeiro.',
  querystring: {
    type: 'object',
    properties: {
      estado: { type: 'string', enum: estados, description: 'Mostra só os pedidos neste estado.' },
    },
    additionalProperties: false,
  },
  response: {
    200: resposta('Os pedidos de alteração.', { type: 'array', items: { $ref: 'AlteracaoCliente#' } }),
    ...respostasErro(400, 401, 403),
  },
};

// GET /api/v1/alteracoes-cliente/:id
export const obterAlteracaoCliente = {
  tags: etiqueta,
  operationId: 'obterAlteracaoCliente',
  summary: 'Mostrar um pedido de alteração',
  description: 'O Administrador vê qualquer pedido; uma clínica só os seus (os outros dão 404).',
  params: paramId,
  response: {
    200: resposta('O pedido de alteração.', { $ref: 'AlteracaoCliente#' }),
    ...respostasErro(400, 401, 403, 404),
  },
};

// POST /api/v1/alteracoes-cliente/:id/aprovar
export const aprovarAlteracaoCliente = {
  tags: etiqueta,
  operationId: 'aprovarAlteracaoCliente',
  summary: 'Aprovar um pedido de alteração',
  description: 'Só o Administrador. Os dados pedidos passam para a clínica. Um pedido já decidido dá 409.',
  params: paramId,
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};

// POST /api/v1/alteracoes-cliente/:id/rejeitar
export const rejeitarAlteracaoCliente = {
  tags: etiqueta,
  operationId: 'rejeitarAlteracaoCliente',
  summary: 'Rejeitar um pedido de alteração',
  description: 'Só o Administrador, com o motivo. Um pedido já decidido dá 409.',
  params: paramId,
  body: {
    type: 'object',
    properties: {
      motivo_rejeicao: { type: 'string', minLength: 1 },
    },
    required: ['motivo_rejeicao'],
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};
