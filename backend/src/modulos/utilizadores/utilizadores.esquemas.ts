import {
  palavraPasseNova,
  paramId,
  resposta,
  respostaCriado,
  respostaId,
  respostaSemConteudo,
  respostasErro,
} from '../../comum/esquemas.ts';

// Esquemas das rotas das contas de acesso (ver comum/esquemas.ts)

const etiqueta = ['Utilizadores'];

// Uma conta, tal como vem da vista vw_utilizador (não tem o password_hash).
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'Utilizador#' }.
export const esquemaUtilizador = {
  $id: 'Utilizador',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    nome: { type: 'string' },
    email: { type: 'string' },
    cargo: { type: 'string' },
    cargo_id: { type: 'integer' },
    cliente: { type: ['string', 'null'], description: 'Nome da clínica (só no cargo Cliente).' },
    cliente_id: { type: ['integer', 'null'] },
    password_temporaria: { type: 'boolean' },
    ativo: { type: 'boolean' },
    aprovado_por: { type: ['integer', 'null'], description: 'Id de quem aprovou; null = à espera de aprovação.' },
    data_aprovacao: { type: ['string', 'null'], format: 'date-time' },
    criado_em: { type: 'string', format: 'date-time' },
  },
  required: [
    'id', 'nome', 'email', 'cargo', 'cargo_id', 'cliente', 'cliente_id',
    'password_temporaria', 'ativo', 'aprovado_por', 'data_aprovacao', 'criado_em',
  ],
};

// Os campos de uma conta que o Administrador pode enviar
const camposUtilizador = {
  nome: { type: 'string', minLength: 1, maxLength: 150 },
  email: { type: 'string', format: 'email', maxLength: 254 },
  cargo_id: { type: 'integer', minimum: 1 },
  cliente_id: { type: 'integer', minimum: 1, description: 'Só no cargo Cliente: a clínica a que a conta pertence.' },
  password: { ...palavraPasseNova, description: 'Palavra-passe temporária.' },
};

// GET /api/v1/utilizadores
export const listarUtilizadores = {
  tags: etiqueta,
  operationId: 'listarUtilizadores',
  summary: 'Listar as contas',
  description: 'Só o Administrador.',
  querystring: {
    type: 'object',
    properties: {
      por_aprovar: { type: 'boolean', description: 'true: só as contas ativas à espera de aprovação.' },
    },
    additionalProperties: false,
  },
  response: {
    200: resposta('As contas (por nome; as por aprovar, da mais antiga para a mais recente).', {
      type: 'array',
      items: { $ref: 'Utilizador#' },
    }),
    ...respostasErro(400, 401, 403),
  },
};

// GET /api/v1/utilizadores/:id
export const obterUtilizador = {
  tags: etiqueta,
  operationId: 'obterUtilizador',
  summary: 'Mostrar uma conta',
  description: 'Só o Administrador.',
  params: paramId,
  response: {
    200: resposta('A conta.', { $ref: 'Utilizador#' }),
    ...respostasErro(400, 401, 403, 404),
  },
};

// POST /api/v1/utilizadores
export const criarUtilizador = {
  tags: etiqueta,
  operationId: 'criarUtilizador',
  summary: 'Criar uma conta',
  description:
    'Só o Administrador. A conta fica logo aprovada, com uma palavra-passe temporária ' +
    'que a pessoa tem de mudar no primeiro login.',
  body: {
    type: 'object',
    properties: camposUtilizador,
    required: ['nome', 'email', 'cargo_id', 'password'],
    additionalProperties: false,
  },
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403, 409),
  },
};

// PATCH /api/v1/utilizadores/:id
export const alterarUtilizador = {
  tags: etiqueta,
  operationId: 'alterarUtilizador',
  summary: 'Alterar uma conta',
  description:
    'Só o Administrador. Muda só os campos enviados. Com "password", essa passa a ser a nova ' +
    'palavra-passe temporária. Não pode desativar a sua própria conta.',
  params: paramId,
  body: {
    type: 'object',
    properties: { ...camposUtilizador, ativo: { type: 'boolean' } },
    minProperties: 1,
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};

// DELETE /api/v1/utilizadores/:id
export const desativarUtilizador = {
  tags: etiqueta,
  operationId: 'desativarUtilizador',
  summary: 'Desativar uma conta',
  description: 'Só o Administrador. Também serve para recusar o registo de uma clínica. Não pode ser a própria conta.',
  params: paramId,
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400, 401, 403, 404),
  },
};

// POST /api/v1/utilizadores/:id/aprovar
export const aprovarUtilizador = {
  tags: etiqueta,
  operationId: 'aprovarUtilizador',
  summary: 'Aprovar uma conta',
  description: 'Só o Administrador. Uma conta já aprovada ou desativada dá 409.',
  params: paramId,
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};
