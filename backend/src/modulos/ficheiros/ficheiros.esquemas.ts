import { paramId, resposta, respostaCriado, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas dos ficheiros (ver comum/esquemas.ts)

const etiqueta = ['Comunicação'];

// Os tipos de ficheiro (tabela tipo_ficheiro; são fixos)
const tipos = ['STL', 'Fotografia', 'Documento', 'Outro'];

// Um ficheiro, tal como vem da vista vw_ficheiro (sem a localizacao: onde está guardado só interessa à API).
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'Ficheiro#' }.
export const esquemaFicheiro = {
  $id: 'Ficheiro',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    ordem_trabalho_id: { type: ['integer', 'null'], description: 'Ficheiro da ordem: a clínica vê-o.' },
    trabalho_id: { type: ['integer', 'null'], description: 'Ficheiro de um trabalho: só o laboratório o vê.' },
    tipo: { type: 'string', enum: tipos },
    nome: { type: 'string', description: 'Nome original do ficheiro.' },
    carregado_por_id: { type: 'integer' },
    carregado_por: { type: 'string' },
    data_carregamento: { type: 'string', format: 'date-time' },
  },
  required: ['id', 'ordem_trabalho_id', 'trabalho_id', 'tipo', 'nome', 'carregado_por_id', 'carregado_por', 'data_carregamento'],
};

// ?tipo=... no envio
const consultaTipo = {
  type: 'object',
  properties: {
    tipo: { type: 'string', enum: tipos, description: 'O tipo do ficheiro enviado.' },
  },
  required: ['tipo'],
  additionalProperties: false,
};

// Como se envia um ficheiro (o corpo não é JSON, por isso fica explicado na descrição)
const comoEnviar =
  'O pedido é multipart/form-data, com o ficheiro no campo "ficheiro" (um de cada vez, até 50 MB). ' +
  'Extensões aceites: .stl, .zip, .ply, .obj, .jpg, .jpeg, .png, .heic, .webp e .pdf.';

// POST /api/v1/ordens/:id/ficheiros
export const enviarFicheiroOrdem = {
  tags: etiqueta,
  operationId: 'enviarFicheiroOrdem',
  summary: 'Enviar um ficheiro para uma ordem',
  description: `A clínica (nas suas ordens) ou o laboratório. A clínica vê-o. ${comoEnviar}`,
  params: paramId,
  querystring: consultaTipo,
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 404, 413, 415),
  },
};

// POST /api/v1/trabalhos/:id/ficheiros
export const enviarFicheiroTrabalho = {
  tags: etiqueta,
  operationId: 'enviarFicheiroTrabalho',
  summary: 'Enviar um ficheiro para um trabalho',
  description: `Só o laboratório (ex.: fotografias da produção). A clínica não o vê. ${comoEnviar}`,
  params: paramId,
  querystring: consultaTipo,
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403, 404, 413, 415),
  },
};

// GET /api/v1/ordens/:id/ficheiros
export const listarFicheirosOrdem = {
  tags: etiqueta,
  operationId: 'listarFicheirosOrdem',
  summary: 'Ficheiros de uma ordem',
  description: 'A clínica só vê os das suas ordens.',
  params: paramId,
  response: {
    200: resposta('Os ficheiros, do mais antigo para o mais recente.', { type: 'array', items: { $ref: 'Ficheiro#' } }),
    ...respostasErro(400, 401, 404),
  },
};

// GET /api/v1/trabalhos/:id/ficheiros
export const listarFicheirosTrabalho = {
  tags: etiqueta,
  operationId: 'listarFicheirosTrabalho',
  summary: 'Ficheiros de um trabalho',
  description: 'Só o laboratório.',
  params: paramId,
  response: {
    200: resposta('Os ficheiros, do mais antigo para o mais recente.', { type: 'array', items: { $ref: 'Ficheiro#' } }),
    ...respostasErro(400, 401, 403, 404),
  },
};

// GET /api/v1/ficheiros/:id
export const descarregarFicheiro = {
  tags: etiqueta,
  operationId: 'descarregarFicheiro',
  summary: 'Descarregar um ficheiro',
  description:
    'Devolve o próprio ficheiro, com o nome original. A clínica só descarrega os ficheiros das suas ordens ' +
    '(os dos trabalhos são internos do laboratório).',
  params: paramId,
  response: {
    200: { description: 'O ficheiro.', type: 'string', format: 'binary' },
    ...respostasErro(400, 401, 404),
  },
};
