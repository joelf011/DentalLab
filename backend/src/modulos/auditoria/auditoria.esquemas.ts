import { resposta, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas do Registo de Atividades (ver comum/esquemas.ts)

// As tabelas com auditoria (as "áreas" do filtro)
const entidades = [
  'cargo', 'utilizador', 'cliente', 'alteracao_cliente', 'estado_ordem', 'ordem_trabalho',
  'tipo_trabalho', 'trabalho', 'etapa_trabalho', 'ficheiro',
];

const jsonOuNulo = {
  type: ['object', 'null'],
  additionalProperties: true,
  description: 'Os valores da linha (nunca tem o hash da palavra-passe).',
};

// Uma linha do Registo de Atividades, tal como vem da vista vw_registo_auditoria
const esquemaAtividade = {
  type: 'object',
  properties: {
    id: { type: 'integer' },
    data_hora: { type: 'string', format: 'date-time' },
    utilizador_id: { type: ['integer', 'null'], description: 'null: feito sem sessão (ex.: registo de uma clínica no site).' },
    autor: { type: ['string', 'null'] },
    cargo_autor: { type: ['string', 'null'] },
    acao: { type: 'string', enum: ['INSERT', 'UPDATE', 'DELETE'] },
    entidade_afetada: { type: 'string', description: 'A tabela alterada.' },
    id_entidade_afetada: { type: ['integer', 'null'] },
    descricao: { type: 'string', examples: ['A ordem n.º 5 passou de "Em avaliação" para "Por iniciar"'] },
    valores_anteriores: jsonOuNulo,
    valores_posteriores: jsonOuNulo,
  },
  required: [
    'id', 'data_hora', 'utilizador_id', 'autor', 'cargo_autor', 'acao', 'entidade_afetada',
    'id_entidade_afetada', 'descricao', 'valores_anteriores', 'valores_posteriores',
  ],
};

// GET /api/v1/auditoria
export const listarAtividades = {
  tags: ['Registo de Atividades'],
  operationId: 'listarAtividades',
  summary: 'Registo de Atividades',
  description:
    'Só o Administrador. Quem alterou o quê e quando, das mais recentes para as mais antigas, por páginas. ' +
    'Os filtros podem juntar-se.',
  querystring: {
    type: 'object',
    properties: {
      pagina: { type: 'integer', minimum: 1, default: 1 },
      tamanho: { type: 'integer', minimum: 1, maximum: 100, default: 50, description: 'Linhas por página.' },
      de: { type: 'string', format: 'date', description: 'Desde este dia (inclusive).' },
      ate: { type: 'string', format: 'date', description: 'Até este dia (inclusive).' },
      utilizador_id: { type: 'integer', minimum: 1, description: 'Só o que esta pessoa fez.' },
      entidade: { type: 'string', enum: entidades, description: 'Só alterações nesta tabela.' },
      pesquisa: { type: 'string', minLength: 1, maxLength: 100, description: 'Texto a procurar na descrição ou no autor.' },
    },
    additionalProperties: false,
  },
  response: {
    200: resposta('Uma página do registo.', {
      type: 'object',
      properties: {
        pagina: { type: 'integer' },
        tamanho_pagina: { type: 'integer' },
        total: { type: 'integer', description: 'Total de linhas com estes filtros (em todas as páginas).' },
        itens: { type: 'array', items: esquemaAtividade },
      },
      required: ['pagina', 'tamanho_pagina', 'total', 'itens'],
    }),
    ...respostasErro(400, 401, 403),
  },
};
