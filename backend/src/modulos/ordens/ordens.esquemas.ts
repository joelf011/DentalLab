import { paramId, resposta, respostaCriado, respostaId, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas das ordens de trabalho (as "encomendas" da clínica) (ver comum/esquemas.ts)

const etiqueta = ['Ordens'];

// Os 8 estados de uma ordem (tabela estado_ordem; são fixos)
const estadosOrdem = [
  'Em avaliação',
  'Rejeitado',
  'Por iniciar',
  'Em processamento',
  'Em espera',
  'Em prova',
  'Concluído',
  'Entregue',
];

const textoOuNulo = { type: ['string', 'null'] };
const dataOuNula = { type: ['string', 'null'], format: 'date' };
const momentoOuNulo = { type: ['string', 'null'], format: 'date-time' };

// Um trabalho de uma ordem, tal como vem da vista vw_trabalho
export const esquemaTrabalho = {
  $id: 'Trabalho',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    ordem_trabalho_id: { type: 'integer' },
    tipo_trabalho: { type: 'string', examples: ['Coroa em zircónia'] },
    natureza: { type: 'string', enum: ['FISICO', 'DIGITAL'] },
    cor: textoOuNulo,
    dentes: { type: 'array', items: { type: 'integer' }, description: 'Numeração FDI.' },
    etapa_atual: { ...textoOuNulo, description: 'Etapa de produção em curso. Vem sempre a null para a clínica.' },
  },
  required: ['id', 'ordem_trabalho_id', 'tipo_trabalho', 'natureza', 'cor', 'dentes', 'etapa_atual'],
};

// Uma ordem, tal como vem da vista vw_ordem_trabalho, com os seus trabalhos.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'Ordem#' }.
export const esquemaOrdem = {
  $id: 'Ordem',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    cliente_id: { type: 'integer' },
    cliente: { type: 'string', description: 'Nome da clínica.' },
    criado_por: { type: 'string', description: 'Nome de quem criou a ordem.' },
    aceite_por: { ...textoOuNulo, description: 'Nome de quem a aceitou no laboratório.' },
    estado_ordem_id: { type: 'integer' },
    estado: { type: 'string', enum: estadosOrdem },
    nome_medico_responsavel: { type: 'string' },
    nome_paciente: textoOuNulo,
    sexo_paciente: { ...textoOuNulo, description: 'M ou F.' },
    idade_paciente: { type: ['integer', 'null'] },
    data_proxima_consulta: dataOuNula,
    observacoes: textoOuNulo,
    prazo_entrega: dataOuNula,
    data_criacao: { type: 'string', format: 'date-time' },
    data_aceitacao: momentoOuNulo,
    data_inicio: momentoOuNulo,
    data_conclusao: momentoOuNulo,
    data_entrega: momentoOuNulo,
    motivo_espera: textoOuNulo,
    motivo_rejeicao: textoOuNulo,
    trabalhos: { type: 'array', items: { $ref: 'Trabalho#' } },
  },
  required: [
    'id', 'cliente_id', 'cliente', 'criado_por', 'aceite_por', 'estado_ordem_id', 'estado',
    'nome_medico_responsavel', 'nome_paciente', 'sexo_paciente', 'idade_paciente',
    'data_proxima_consulta', 'observacoes', 'prazo_entrega', 'data_criacao', 'data_aceitacao',
    'data_inicio', 'data_conclusao', 'data_entrega', 'motivo_espera', 'motivo_rejeicao', 'trabalhos',
  ],
};

// Os dados do paciente e da ordem que se podem enviar (POST e PATCH)
const camposOrdem = {
  nome_medico_responsavel: { type: 'string', minLength: 1, maxLength: 150 },
  nome_paciente: { type: 'string', maxLength: 150 },
  sexo_paciente: { type: 'string', enum: ['M', 'F'] },
  idade_paciente: { type: 'integer', minimum: 0, maximum: 130 },
  data_proxima_consulta: { type: 'string', format: 'date', examples: ['2026-12-15'] },
  observacoes: { type: 'string', description: 'Instruções clínicas.' },
};

// Os campos de um trabalho que se podem enviar
export const camposTrabalho = {
  natureza: { type: 'string', enum: ['FISICO', 'DIGITAL'] },
  cor: { type: 'string', maxLength: 10, examples: ['A2'] },
  dentes: {
    type: 'array',
    minItems: 1,
    items: { type: 'integer', minimum: 11, maximum: 85 },
    description: 'Numeração FDI (11 a 48; 51 a 85 nos dentes de leite).',
    examples: [[11, 12]],
  },
};

// GET /api/v1/ordens
export const listarOrdens = {
  tags: etiqueta,
  operationId: 'listarOrdens',
  summary: 'Listar as ordens de trabalho (encomendas)',
  description:
    'A clínica vê só as suas; o laboratório (Administrador e Colaborador) vê todas. As mais recentes primeiro, ' +
    'cada uma com os seus trabalhos.',
  querystring: {
    type: 'object',
    properties: {
      estado: { type: 'string', enum: estadosOrdem, description: 'Mostra só as ordens neste estado.' },
    },
    additionalProperties: false,
  },
  response: {
    200: resposta('As ordens.', { type: 'array', items: { $ref: 'Ordem#' } }),
    ...respostasErro(400, 401),
  },
};

// GET /api/v1/ordens/:id
export const obterOrdem = {
  tags: etiqueta,
  operationId: 'obterOrdem',
  summary: 'Mostrar uma ordem de trabalho',
  description: 'A clínica só vê as suas (as outras dão 404).',
  params: paramId,
  response: {
    200: resposta('A ordem, com os seus trabalhos.', { $ref: 'Ordem#' }),
    ...respostasErro(400, 401, 404),
  },
};

// POST /api/v1/ordens
export const criarOrdem = {
  tags: etiqueta,
  operationId: 'criarOrdem',
  summary: 'Criar uma encomenda (ordem com os seus trabalhos)',
  description:
    'A clínica cria para si; o Administrador indica o cliente_id. A ordem e os trabalhos são gravados de uma vez ' +
    '(se um trabalho tiver um erro, não fica nada gravado). A ordem começa "Em avaliação" e cada trabalho recebe ' +
    'as etapas do seu tipo.',
  body: {
    type: 'object',
    properties: {
      cliente_id: { type: 'integer', minimum: 1, description: 'Só o Administrador o indica.' },
      ...camposOrdem,
      trabalhos: {
        type: 'array',
        minItems: 1,
        items: {
          type: 'object',
          properties: {
            tipo_trabalho_id: { type: 'integer', minimum: 1 },
            ...camposTrabalho,
          },
          required: ['tipo_trabalho_id', 'natureza', 'dentes'],
          additionalProperties: false,
        },
      },
    },
    required: ['nome_medico_responsavel', 'trabalhos'],
    additionalProperties: false,
  },
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403),
  },
};

// PATCH /api/v1/ordens/:id
export const alterarOrdem = {
  tags: etiqueta,
  operationId: 'alterarOrdem',
  summary: 'Alterar os dados de uma ordem',
  description: 'Só o Administrador. Muda só os campos enviados. O estado muda-se com POST /ordens/:id/estado.',
  params: paramId,
  body: {
    type: 'object',
    properties: {
      ...camposOrdem,
      prazo_entrega: { type: 'string', format: 'date' },
    },
    minProperties: 1,
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404),
  },
};

// POST /api/v1/ordens/:id/aceitar
export const aceitarOrdem = {
  tags: etiqueta,
  operationId: 'aceitarOrdem',
  summary: 'Aceitar uma ordem',
  description:
    'O laboratório (Administrador ou Colaborador) aceita uma ordem "Em avaliação", com o prazo de entrega. ' +
    'A ordem passa a "Por iniciar". Se já não estiver "Em avaliação", dá 409.',
  params: paramId,
  body: {
    type: 'object',
    properties: {
      prazo_entrega: { type: 'string', format: 'date', description: 'De hoje em diante.' },
    },
    required: ['prazo_entrega'],
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};

// POST /api/v1/ordens/:id/estado
export const mudarEstadoOrdem = {
  tags: etiqueta,
  operationId: 'mudarEstadoOrdem',
  summary: 'Mudar o estado de uma ordem',
  description:
    'O laboratório (Administrador ou Colaborador). "Em espera" e "Rejeitado" precisam de motivo. ' +
    '"Por iniciar" é pela aceitação; "Em processamento" e "Concluído" também mudam sozinhos quando as etapas ' +
    'começam e acabam.',
  params: paramId,
  body: {
    type: 'object',
    properties: {
      estado: { type: 'string', enum: ['Rejeitado', 'Em processamento', 'Em espera', 'Em prova', 'Concluído', 'Entregue'] },
      motivo: { type: 'string', minLength: 1 },
    },
    required: ['estado'],
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};
