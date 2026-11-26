import {
  paramId,
  resposta,
  respostaCriado,
  respostaId,
  respostaSemConteudo,
  respostasErro,
} from '../../comum/esquemas.ts';

// Esquemas das rotas das etapas do catálogo (ver comum/esquemas.ts)

const etiqueta = ['Catálogo'];

// Uma etapa de produção do catálogo, tal como vem da vista vw_etapa.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'Etapa#' }.
export const esquemaEtapa = {
  $id: 'Etapa',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    nome: { type: 'string', examples: ['Fresagem (CAM)'] },
    descricao: { type: ['string', 'null'] },
    ativa: { type: 'boolean' },
  },
  required: ['id', 'nome', 'descricao', 'ativa'],
};

// Os campos de uma etapa que o Administrador pode enviar
const camposEtapa = {
  nome: { type: 'string', minLength: 1, maxLength: 100 },
  descricao: { type: 'string' },
};

// GET /api/v1/etapas
export const listarEtapas = {
  tags: etiqueta,
  operationId: 'listarEtapas',
  summary: 'Listar as etapas de produção',
  description: 'Só o Administrador (ecrã Etapas de Produção). Inclui as desativadas.',
  response: {
    200: resposta('As etapas, por nome.', { type: 'array', items: { $ref: 'Etapa#' } }),
    ...respostasErro(401, 403),
  },
};

// POST /api/v1/etapas
export const criarEtapa = {
  tags: etiqueta,
  operationId: 'criarEtapa',
  summary: 'Criar uma etapa de produção',
  description: 'Só o Administrador.',
  body: {
    type: 'object',
    properties: camposEtapa,
    required: ['nome'],
    additionalProperties: false,
  },
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403, 409),
  },
};

// PATCH /api/v1/etapas/:id
export const alterarEtapa = {
  tags: etiqueta,
  operationId: 'alterarEtapa',
  summary: 'Alterar uma etapa de produção',
  description: 'Só o Administrador. Muda só os campos enviados; "ativa": true reativa uma etapa desativada.',
  params: paramId,
  body: {
    type: 'object',
    properties: { ...camposEtapa, ativa: { type: 'boolean' } },
    minProperties: 1,
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};

// DELETE /api/v1/etapas/:id
export const desativarEtapa = {
  tags: etiqueta,
  operationId: 'desativarEtapa',
  summary: 'Desativar uma etapa de produção',
  description:
    'Só o Administrador. Não apaga: deixa de se poder usar nas listas dos tipos de trabalho. ' +
    'Os trabalhos que já a têm não mudam.',
  params: paramId,
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400, 401, 403, 404),
  },
};
