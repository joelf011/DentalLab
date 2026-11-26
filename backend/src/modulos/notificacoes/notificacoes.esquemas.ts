import { paramId, resposta, respostaSemConteudo, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas das notificações (ver comum/esquemas.ts)

const etiqueta = ['Comunicação'];

// Uma notificação, tal como vem da vista vw_notificacao
const esquemaNotificacao = {
  type: 'object',
  properties: {
    id: { type: 'integer' },
    ordem_trabalho_id: { type: ['integer', 'null'] },
    trabalho_id: { type: ['integer', 'null'] },
    mensagem: { type: 'string', examples: ['A ordem n.º 5 passou para o estado "Em prova".'] },
    data_criacao: { type: 'string', format: 'date-time' },
    data_leitura: { type: ['string', 'null'], format: 'date-time' },
    lida: { type: 'boolean' },
  },
  required: ['id', 'ordem_trabalho_id', 'trabalho_id', 'mensagem', 'data_criacao', 'data_leitura', 'lida'],
};

// GET /api/v1/notificacoes
export const listarNotificacoes = {
  tags: etiqueta,
  operationId: 'listarNotificacoes',
  summary: 'As minhas notificações',
  description:
    'As notificações de quem está ligado, das mais recentes para as mais antigas (no máximo 100). ' +
    'Criam-se sozinhas na base de dados: a clínica recebe as mudanças de estado das suas ordens; ' +
    'os administradores, as ordens novas.',
  querystring: {
    type: 'object',
    properties: {
      por_ler: { type: 'boolean', description: 'true: só as que ainda não foram lidas (ex.: para o número no sino).' },
    },
    additionalProperties: false,
  },
  response: {
    200: resposta('As notificações.', { type: 'array', items: esquemaNotificacao }),
    ...respostasErro(400, 401),
  },
};

// POST /api/v1/notificacoes/:id/lida
export const marcarNotificacaoLida = {
  tags: etiqueta,
  operationId: 'marcarNotificacaoLida',
  summary: 'Marcar uma notificação como lida',
  description: 'Só as próprias (as de outra pessoa dão 404).',
  params: paramId,
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400, 401, 404),
  },
};

// POST /api/v1/notificacoes/lidas
export const marcarTodasLidas = {
  tags: etiqueta,
  operationId: 'marcarTodasLidas',
  summary: 'Marcar todas as notificações como lidas',
  response: {
    204: respostaSemConteudo,
    ...respostasErro(401),
  },
};
