import { resposta, respostaErro, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas da autenticação (ver comum/esquemas.ts)

const etiqueta = ['Autenticação'];

// Quem está ligado: vem no login e em GET /auth/eu.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'UtilizadorLigado#' }.
export const esquemaUtilizadorLigado = {
  $id: 'UtilizadorLigado',
  type: 'object',
  description: 'Quem está ligado.',
  properties: {
    id: { type: 'integer' },
    nome: { type: 'string' },
    cargo: { type: 'string', description: 'Administrador, Colaborador ou Cliente.' },
    cliente_id: { type: ['integer', 'null'], description: 'A clínica da conta (só no cargo Cliente).' },
    email: { type: 'string' },
    password_temporaria: {
      type: 'boolean',
      description: 'Se for true, a pessoa tem de mudar a palavra-passe antes de continuar.',
    },
  },
  required: ['id', 'nome', 'cargo', 'cliente_id', 'email', 'password_temporaria'],
};

// POST /api/v1/auth/login
export const fazerLogin = {
  tags: etiqueta,
  operationId: 'fazerLogin',
  summary: 'Fazer login',
  description: 'Devolve o token, para enviar nos pedidos seguintes (Authorization: Bearer <token>), e quem está ligado.',
  security: [], // pública: é aqui que se obtém o token
  body: {
    type: 'object',
    properties: {
      email: { type: 'string', minLength: 1 },
      password: { type: 'string', minLength: 1 },
    },
    required: ['email', 'password'],
    additionalProperties: false,
  },
  response: {
    200: resposta(
      'Login feito.',
      {
        type: 'object',
        properties: {
          token: { type: 'string', description: 'Válido durante 7 dias.' },
          utilizador: { $ref: 'UtilizadorLigado#' },
        },
        required: ['token', 'utilizador'],
      },
      'no-store',
    ),
    ...respostasErro(400),
    // O 401 do login não traz WWW-Authenticate: não é uma sessão que falhou, são as credenciais.
    401: respostaErro('Email ou palavra-passe incorretos (a mesma resposta nos dois casos).'),
    403: respostaErro('A conta está desativada ou ainda não foi aprovada pelo laboratório.'),
  },
};

// GET /api/v1/auth/eu
export const obterUtilizadorLigado = {
  tags: etiqueta,
  operationId: 'obterUtilizadorLigado',
  summary: 'Saber quem está ligado',
  description: 'O frontend chama esta rota ao abrir, para saber se o token guardado ainda serve.',
  response: {
    200: resposta('Quem está ligado, com os dados atuais da base de dados.', { $ref: 'UtilizadorLigado#' }, 'no-store'),
    ...respostasErro(401),
  },
};
