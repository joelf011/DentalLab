import {
  paramId,
  resposta,
  respostaCriado,
  respostaId,
  respostaSemConteudo,
  respostasErro,
} from '../../comum/esquemas.ts';

// Esquemas das rotas dos cargos (ver comum/esquemas.ts)

const etiqueta = ['Cargos'];

// Um cargo, tal como vem da vista vw_cargo.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'Cargo#' }.
export const esquemaCargo = {
  $id: 'Cargo',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    designacao: { type: 'string', examples: ['Colaborador'] },
  },
  required: ['id', 'designacao'],
};

// O que o frontend envia para criar ou alterar: { "designacao": "Técnico" }
const dadosCargo = {
  type: 'object',
  properties: {
    designacao: { type: 'string', minLength: 1, maxLength: 50 },
  },
  required: ['designacao'],
  additionalProperties: false,
};

// GET /api/v1/cargos
export const listarCargos = {
  tags: etiqueta,
  operationId: 'listarCargos',
  summary: 'Listar os cargos',
  description: 'Qualquer pessoa com login.',
  response: {
    200: resposta('Os cargos, por id.', { type: 'array', items: { $ref: 'Cargo#' } }),
    ...respostasErro(401),
  },
};

// GET /api/v1/cargos/:id
export const obterCargo = {
  tags: etiqueta,
  operationId: 'obterCargo',
  summary: 'Mostrar um cargo',
  description: 'Qualquer pessoa com login.',
  params: paramId,
  response: {
    200: resposta('O cargo.', { $ref: 'Cargo#' }),
    ...respostasErro(400, 401, 404),
  },
};

// POST /api/v1/cargos
export const criarCargo = {
  tags: etiqueta,
  operationId: 'criarCargo',
  summary: 'Criar um cargo',
  description: 'Só o Administrador.',
  body: dadosCargo,
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403, 409),
  },
};

// PATCH /api/v1/cargos/:id
export const alterarCargo = {
  tags: etiqueta,
  operationId: 'alterarCargo',
  summary: 'Alterar um cargo',
  description: 'Só o Administrador.',
  params: paramId,
  body: dadosCargo,
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};

// DELETE /api/v1/cargos/:id
export const apagarCargo = {
  tags: etiqueta,
  operationId: 'apagarCargo',
  summary: 'Apagar um cargo',
  description: 'Só o Administrador, e só se o cargo não tiver utilizadores (senão, 400).',
  params: paramId,
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400, 401, 403, 404),
  },
};
