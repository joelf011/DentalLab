import {
  paramId,
  resposta,
  respostaCriado,
  respostaId,
  respostaSemConteudo,
  respostasErro,
} from '../../comum/esquemas.ts';

// Esquemas das rotas dos tipos de trabalho (ver comum/esquemas.ts)

const etiqueta = ['Catálogo'];

// Um tipo de trabalho, tal como vem da vista vw_tipo_trabalho.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'TipoTrabalho#' }.
export const esquemaTipoTrabalho = {
  $id: 'TipoTrabalho',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    nome: { type: 'string', examples: ['Coroa em zircónia'] },
    descricao: { type: ['string', 'null'] },
    ativo: { type: 'boolean' },
  },
  required: ['id', 'nome', 'descricao', 'ativo'],
};

// Uma etapa da lista de um tipo de trabalho (vista vw_etapa_tipo_trabalho)
const esquemaEtapaDoTipo = {
  type: 'object',
  properties: {
    ordem: { type: 'integer', description: 'Posição da etapa: 1, 2, 3...' },
    etapa_id: { type: 'integer' },
    nome: { type: 'string' },
  },
  required: ['ordem', 'etapa_id', 'nome'],
};

// Os campos de um tipo de trabalho que o Administrador pode enviar
const camposTipoTrabalho = {
  nome: { type: 'string', minLength: 1, maxLength: 100 },
  descricao: { type: 'string' },
};

// GET /api/v1/tipos-trabalho
export const listarTiposTrabalho = {
  tags: etiqueta,
  operationId: 'listarTiposTrabalho',
  summary: 'Listar os tipos de trabalho',
  description:
    'Qualquer pessoa com login. O Administrador vê todos (para os gerir); os outros só os ativos ' +
    '(ex.: para escolher na nova encomenda).',
  response: {
    200: resposta('Os tipos de trabalho, por nome.', { type: 'array', items: { $ref: 'TipoTrabalho#' } }),
    ...respostasErro(401),
  },
};

// POST /api/v1/tipos-trabalho
export const criarTipoTrabalho = {
  tags: etiqueta,
  operationId: 'criarTipoTrabalho',
  summary: 'Criar um tipo de trabalho',
  description: 'Só o Administrador. Depois, as etapas definem-se com PUT /tipos-trabalho/:id/etapas.',
  body: {
    type: 'object',
    properties: camposTipoTrabalho,
    required: ['nome'],
    additionalProperties: false,
  },
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403, 409),
  },
};

// PATCH /api/v1/tipos-trabalho/:id
export const alterarTipoTrabalho = {
  tags: etiqueta,
  operationId: 'alterarTipoTrabalho',
  summary: 'Alterar um tipo de trabalho',
  description: 'Só o Administrador. Muda só os campos enviados; "ativo": true reativa um tipo desativado.',
  params: paramId,
  body: {
    type: 'object',
    properties: { ...camposTipoTrabalho, ativo: { type: 'boolean' } },
    minProperties: 1,
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};

// DELETE /api/v1/tipos-trabalho/:id
export const desativarTipoTrabalho = {
  tags: etiqueta,
  operationId: 'desativarTipoTrabalho',
  summary: 'Desativar um tipo de trabalho',
  description:
    'Só o Administrador. Não apaga (os trabalhos antigos continuam a referi-lo): deixa de aparecer ' +
    'para escolher nas encomendas novas.',
  params: paramId,
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400, 401, 403, 404),
  },
};

// GET /api/v1/tipos-trabalho/:id/etapas
export const listarEtapasDoTipo = {
  tags: etiqueta,
  operationId: 'listarEtapasDoTipo',
  summary: 'Etapas de um tipo de trabalho',
  description:
    'Administrador e Colaborador (a clínica não vê as etapas de produção). Estas etapas são copiadas ' +
    'para cada trabalho novo deste tipo.',
  params: paramId,
  response: {
    200: resposta('As etapas, pela ordem.', { type: 'array', items: esquemaEtapaDoTipo }),
    ...respostasErro(400, 401, 403, 404),
  },
};

// PUT /api/v1/tipos-trabalho/:id/etapas
export const definirEtapasDoTipo = {
  tags: etiqueta,
  operationId: 'definirEtapasDoTipo',
  summary: 'Definir as etapas de um tipo de trabalho',
  description:
    'Só o Administrador. Substitui a lista inteira pela ordem enviada. Os trabalhos já criados não mudam ' +
    '(têm a sua própria cópia das etapas).',
  params: paramId,
  body: {
    type: 'object',
    properties: {
      etapas: {
        type: 'array',
        minItems: 1,
        items: { type: 'integer', minimum: 1 },
        description: 'Ids das etapas (GET /etapas), pela ordem em que se fazem.',
        examples: [[3, 1, 5]],
      },
    },
    required: ['etapas'],
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404),
  },
};
