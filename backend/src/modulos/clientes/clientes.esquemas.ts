import {
  paramId,
  resposta,
  respostaCriado,
  respostaId,
  respostaSemConteudo,
  respostasErro,
} from '../../comum/esquemas.ts';

// Esquemas das rotas dos clientes (ver comum/esquemas.ts)

const etiqueta = ['Clientes'];

// Uma clínica, tal como vem da vista vw_cliente.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'Cliente#' }.
export const esquemaCliente = {
  $id: 'Cliente',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    nome: { type: 'string' },
    nif: { type: 'string' },
    morada_faturacao: { type: ['string', 'null'] },
    email: { type: ['string', 'null'] },
    telefone: { type: ['string', 'null'] },
    ativo: { type: 'boolean' },
    criado_em: { type: 'string', format: 'date-time' },
    estado: {
      type: 'string',
      enum: ['Ativo', 'A aguardar validação', 'Suspenso'],
      description: 'Suspenso: desativada. A aguardar validação: tem uma conta por aprovar (ver GET /utilizadores?por_aprovar=true).',
    },
    trabalhos_ativos: { type: 'integer', description: 'Trabalhos das ordens que ainda não acabaram.' },
  },
  required: ['id', 'nome', 'nif', 'morada_faturacao', 'email', 'telefone', 'ativo', 'criado_em', 'estado', 'trabalhos_ativos'],
};

// Os campos de uma clínica que o frontend pode enviar
const camposCliente = {
  nome: { type: 'string', minLength: 1, maxLength: 150 },
  nif: { type: 'string', pattern: '^[0-9]{9}$', description: '9 algarismos.' },
  morada_faturacao: { type: 'string', maxLength: 255 },
  email: { type: 'string', format: 'email', maxLength: 254 },
  telefone: { type: 'string', maxLength: 20 },
};

// GET /api/v1/clientes
export const listarClientes = {
  tags: etiqueta,
  operationId: 'listarClientes',
  summary: 'Listar as clínicas',
  description: 'Só o Administrador.',
  response: {
    200: resposta('As clínicas, por nome.', { type: 'array', items: { $ref: 'Cliente#' } }),
    ...respostasErro(401, 403),
  },
};

// GET /api/v1/clientes/:id
export const obterCliente = {
  tags: etiqueta,
  operationId: 'obterCliente',
  summary: 'Mostrar uma clínica',
  description: 'O Administrador vê qualquer clínica; uma clínica só vê a sua (as outras dão 404).',
  params: paramId,
  response: {
    200: resposta('A clínica.', { $ref: 'Cliente#' }),
    ...respostasErro(400, 401, 403, 404),
  },
};

// POST /api/v1/clientes
export const criarCliente = {
  tags: etiqueta,
  operationId: 'criarCliente',
  summary: 'Criar uma clínica',
  description: 'Só o Administrador. Cria a clínica sem conta de acesso (a conta cria-se em Utilizadores).',
  body: {
    type: 'object',
    properties: camposCliente,
    required: ['nome', 'nif'],
    additionalProperties: false,
  },
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403, 409),
  },
};

// PATCH /api/v1/clientes/:id
export const alterarCliente = {
  tags: etiqueta,
  operationId: 'alterarCliente',
  summary: 'Alterar uma clínica',
  description:
    'Só o Administrador. Muda só os campos enviados. "ativo": false desativa a clínica e as contas dela; ' +
    '"ativo": true reativa tudo.',
  params: paramId,
  body: {
    type: 'object',
    properties: { ...camposCliente, ativo: { type: 'boolean' } },
    minProperties: 1,
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};

// DELETE /api/v1/clientes/:id
export const desativarCliente = {
  tags: etiqueta,
  operationId: 'desativarCliente',
  summary: 'Desativar uma clínica',
  description:
    'Só o Administrador. Desativa a clínica e as contas dela; não apaga, porque há o histórico das ordens.',
  params: paramId,
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400, 401, 403, 404),
  },
};
