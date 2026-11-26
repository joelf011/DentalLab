import { resposta, respostaErro, respostaSemConteudo, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas da autenticação: token da app e sessão do site (ver comum/esquemas.ts)

const etiqueta = ['Autenticação'];

// Quem está ligado: vem no login e em GET /sessao.
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

// O que se envia para entrar (na app e no site)
const credenciais = {
  type: 'object',
  properties: {
    email: { type: 'string', minLength: 1 },
    password: { type: 'string', minLength: 1 },
  },
  required: ['email', 'password'],
  additionalProperties: false,
};

// Erros de quem tenta entrar
const errosEntrar = {
  ...respostasErro(400),
  // Este 401 não traz WWW-Authenticate: não é uma sessão que falhou, são as credenciais.
  401: respostaErro('Email ou palavra-passe incorretos (a mesma resposta nos dois casos).'),
  403: respostaErro('A conta está desativada ou ainda não foi aprovada pelo laboratório.'),
};

// O cookie da sessão, para a documentação
const cookieCriado = {
  type: 'string',
  description: 'sessao=<token>; Max-Age=604800; Path=/api/v1; HttpOnly; SameSite=Strict',
};
const cookieApagado = {
  type: 'string',
  description: 'sessao=; Path=/api/v1; Expires=Thu, 01 Jan 1970 00:00:00 GMT (o navegador apaga-o)',
};

// POST /api/v1/tokens
export const criarToken = {
  tags: etiqueta,
  operationId: 'criarToken',
  summary: 'Entrar na app (token)',
  description:
    'Para a app: devolve o token, que se guarda no telemóvel e se envia nos pedidos seguintes ' +
    '(Authorization: Bearer <token>). Válido durante 7 dias.',
  security: [], // pública: é aqui que se obtém o token
  body: credenciais,
  response: {
    200: resposta(
      'Entrou.',
      {
        type: 'object',
        properties: {
          token: { type: 'string' },
          utilizador: { $ref: 'UtilizadorLigado#' },
        },
        required: ['token', 'utilizador'],
      },
      'no-store',
    ),
    ...errosEntrar,
  },
};

// POST /api/v1/sessao
export const criarSessao = {
  tags: etiqueta,
  operationId: 'criarSessao',
  summary: 'Entrar no site (cookie)',
  description:
    'Para o site: guarda o token no cookie "sessao", que o navegador envia sozinho nos pedidos seguintes ' +
    '(no fetch: credentials: "include"). O cookie é HttpOnly: o JavaScript da página não o consegue ler, ' +
    'por isso o token não vem no corpo. Válido durante 7 dias.',
  security: [], // pública: é aqui que se cria a sessão
  body: credenciais,
  response: {
    200: {
      ...resposta('Sessão iniciada.', { $ref: 'UtilizadorLigado#' }, 'no-store'),
      headers: {
        'Cache-Control': { type: 'string', enum: ['no-store'] },
        'Set-Cookie': cookieCriado,
      },
    },
    ...errosEntrar,
  },
};

// GET /api/v1/sessao
export const obterSessao = {
  tags: etiqueta,
  operationId: 'obterSessao',
  summary: 'Saber quem está ligado',
  description:
    'Com o cookie (site) ou o token (app). O site chama-a ao abrir a página, para saber se a sessão continua; ' +
    'a app, ao abrir, para saber se o token guardado ainda serve.',
  response: {
    200: resposta('Quem está ligado, com os dados atuais da base de dados.', { $ref: 'UtilizadorLigado#' }, 'no-store'),
    ...respostasErro(401),
  },
};

// DELETE /api/v1/sessao
export const terminarSessao = {
  tags: etiqueta,
  operationId: 'terminarSessao',
  summary: 'Sair do site',
  description: 'Pede ao navegador que apague o cookie. Na app, sair é apagar o token guardado no telemóvel.',
  security: [], // pública: tem de funcionar mesmo que a sessão já tenha expirado
  response: {
    204: {
      ...respostaSemConteudo,
      headers: { ...respostaSemConteudo.headers, 'Set-Cookie': cookieApagado },
    },
  },
};
