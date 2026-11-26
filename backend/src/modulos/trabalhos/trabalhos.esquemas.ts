import { paramId, resposta, respostaId, respostasErro } from '../../comum/esquemas.ts';
import { camposTrabalho } from '../ordens/ordens.esquemas.ts';

// Esquemas das rotas dos trabalhos e da sua produção (ver comum/esquemas.ts)

const etiqueta = ['Trabalhos'];

const textoOuNulo = { type: ['string', 'null'] };
const momentoOuNulo = { type: ['string', 'null'], format: 'date-time' };

// Uma etapa da produção de um trabalho, tal como vem da vista vw_etapa_trabalho.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'EtapaTrabalho#' }.
export const esquemaEtapaTrabalho = {
  $id: 'EtapaTrabalho',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    trabalho_id: { type: 'integer' },
    nome: { type: 'string' },
    ordem: { type: 'integer', description: 'Posição na sequência: 1, 2, 3...' },
    responsavel_id: { type: ['integer', 'null'] },
    responsavel: { ...textoOuNulo, description: 'Nome de quem assumiu a etapa (ou a quem foi atribuída).' },
    data_inicio: momentoOuNulo,
    data_conclusao: momentoOuNulo,
    estado: { type: 'string', enum: ['Por iniciar', 'Em curso', 'Concluída'] },
  },
  required: ['id', 'trabalho_id', 'nome', 'ordem', 'responsavel_id', 'responsavel', 'data_inicio', 'data_conclusao', 'estado'],
};

// Um trabalho como o laboratório o vê: o trabalho (vw_trabalho), dados da sua ordem e as etapas, pela ordem.
export const esquemaTrabalhoEmProducao = {
  $id: 'TrabalhoEmProducao',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    ordem_trabalho_id: { type: 'integer' },
    tipo_trabalho: { type: 'string' },
    natureza: { type: 'string', enum: ['FISICO', 'DIGITAL'] },
    cor: textoOuNulo,
    dentes: { type: 'array', items: { type: 'integer' } },
    etapa_atual: { ...textoOuNulo, description: 'Primeira etapa por concluir (null quando acabaram todas).' },
    cliente: { type: 'string', description: 'Nome da clínica.' },
    nome_paciente: textoOuNulo,
    estado_ordem: { type: 'string' },
    prazo_entrega: { type: ['string', 'null'], format: 'date' },
    etapas: { type: 'array', items: { $ref: 'EtapaTrabalho#' } },
  },
  required: [
    'id', 'ordem_trabalho_id', 'tipo_trabalho', 'natureza', 'cor', 'dentes', 'etapa_atual',
    'cliente', 'nome_paciente', 'estado_ordem', 'prazo_entrega', 'etapas',
  ],
};

// GET /api/v1/trabalhos
export const listarTrabalhos = {
  tags: etiqueta,
  operationId: 'listarTrabalhos',
  summary: 'Listar os trabalhos, com as etapas de produção',
  description:
    'O laboratório (Administrador e Colaborador). Os de prazo mais próximo primeiro. ' +
    'Com ?abertos=true, só os das ordens que ainda não acabaram (sem Concluído, Entregue e Rejeitado). ' +
    'Disponíveis, os meus e prazos filtram-se a partir daqui.',
  querystring: {
    type: 'object',
    properties: {
      abertos: { type: 'boolean', description: 'true: só os trabalhos de ordens por acabar.' },
    },
    additionalProperties: false,
  },
  response: {
    200: resposta('Os trabalhos.', { type: 'array', items: { $ref: 'TrabalhoEmProducao#' } }),
    ...respostasErro(400, 401, 403),
  },
};

// GET /api/v1/trabalhos/:id
export const obterTrabalho = {
  tags: etiqueta,
  operationId: 'obterTrabalho',
  summary: 'Mostrar um trabalho, com as etapas de produção',
  description: 'O laboratório (Administrador e Colaborador).',
  params: paramId,
  response: {
    200: resposta('O trabalho.', { $ref: 'TrabalhoEmProducao#' }),
    ...respostasErro(400, 401, 403, 404),
  },
};

// PATCH /api/v1/trabalhos/:id
export const alterarTrabalho = {
  tags: etiqueta,
  operationId: 'alterarTrabalho',
  summary: 'Alterar um trabalho',
  description:
    'Só o Administrador. Muda só os campos enviados; "dentes" substitui a lista toda. ' +
    'O tipo de trabalho não muda (as etapas já foram copiadas dele).',
  params: paramId,
  body: {
    type: 'object',
    properties: camposTrabalho,
    minProperties: 1,
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404),
  },
};

// POST /api/v1/etapas-trabalho/:id/assumir
export const assumirEtapa = {
  tags: etiqueta,
  operationId: 'assumirEtapa',
  summary: 'Assumir uma etapa (e começá-la)',
  description:
    'O laboratório. Quem assume fica responsável e a etapa começa agora. Uma etapa atribuída a outra pessoa ' +
    'só pode ser assumida por ela ou pelo Administrador (senão, 409). Também dá 409 se a etapa anterior ainda ' +
    'não acabou, se esta já começou, ou se a ordem não está em produção.',
  params: paramId,
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};

// POST /api/v1/etapas-trabalho/:id/concluir
export const concluirEtapa = {
  tags: etiqueta,
  operationId: 'concluirEtapa',
  summary: 'Concluir uma etapa',
  description:
    'Só quem a assumiu, ou o Administrador. Escolhe quem fica com a etapa seguinte (ninguém, eu ou outro ' +
    'colaborador) e se o trabalho avança ou vai para prova na clínica (a ordem passa a "Em prova"). ' +
    'Para pôr a ordem em espera usa-se POST /ordens/:id/estado.',
  params: paramId,
  body: {
    type: 'object',
    properties: {
      atribuicao: {
        type: 'string',
        enum: ['livre', 'eu', 'outro'],
        description: 'Quem fica com a etapa seguinte: ninguém (fica disponível), eu, ou outro colaborador.',
      },
      colaborador_id: { type: 'integer', minimum: 1, description: 'Só com "atribuicao": "outro" (ver GET /colaboradores).' },
      destino: {
        type: 'string',
        enum: ['avancar', 'prova'],
        description: 'avancar: segue a produção. prova: a ordem passa a "Em prova" (prova clínica).',
      },
    },
    required: ['atribuicao', 'destino'],
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    ...respostasErro(400, 401, 403, 404, 409),
  },
};
