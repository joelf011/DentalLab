import {
  palavraPasseNova,
  respostaCriado,
  respostaId,
  respostaSemConteudo,
  respostasErro,
} from '../../comum/esquemas.ts';

// Esquemas das rotas da conta: registo de uma clínica, palavra-passe e recuperação (ver comum/esquemas.ts)

const etiqueta = ['Conta'];

// POST /api/v1/registos
export const registarClinica = {
  tags: etiqueta,
  operationId: 'registarClinica',
  summary: 'Registar uma clínica',
  description:
    'Cria a clínica e a conta de acesso. A conta fica à espera de aprovação do Administrador; ' +
    'até lá, o login responde 403.',
  security: [], // pública: quem se regista ainda não tem conta
  body: {
    type: 'object',
    properties: {
      nome: { type: 'string', minLength: 1, maxLength: 150 },
      nif: { type: 'string', pattern: '^[0-9]{9}$', description: '9 algarismos.' },
      morada_faturacao: { type: 'string', maxLength: 255 },
      telefone: { type: 'string', maxLength: 20 },
      email: { type: 'string', format: 'email', maxLength: 254, description: 'Email da clínica e email de login.' },
      password: palavraPasseNova,
    },
    required: ['nome', 'nif', 'email', 'password'],
    additionalProperties: false,
  },
  response: {
    201: respostaCriado,
    ...respostasErro(400, 409),
  },
};

// PUT /api/v1/conta/palavra-passe
export const mudarPalavraPasse = {
  tags: etiqueta,
  operationId: 'mudarPalavraPasse',
  summary: 'Mudar a palavra-passe de quem está ligado',
  description: 'A palavra-passe deixa de ser temporária.',
  body: {
    type: 'object',
    properties: {
      password_atual: { type: 'string', minLength: 1 },
      password_nova: palavraPasseNova,
    },
    required: ['password_atual', 'password_nova'],
    additionalProperties: false,
  },
  response: {
    200: respostaId,
    // 400 e não 401 quando a atual está errada: o frontend trata o 401 como "sessão terminada".
    ...respostasErro(400, 401),
  },
};

// POST /api/v1/recuperacoes
export const pedirRecuperacao = {
  tags: etiqueta,
  operationId: 'pedirRecuperacao',
  summary: 'Pedir para recuperar a palavra-passe',
  description:
    'Se o email for de uma conta ativa, envia-lhe um link para escolher uma palavra-passe nova (válido durante ' +
    '1 hora). A resposta é sempre 204, haja ou não conta com esse email: assim não se descobre que emails têm conta.',
  security: [], // pública: quem se esqueceu da palavra-passe não consegue entrar
  body: {
    type: 'object',
    properties: {
      email: { type: 'string', format: 'email', maxLength: 254 },
    },
    required: ['email'],
    additionalProperties: false,
  },
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400),
  },
};

// POST /api/v1/recuperacoes/concluir
export const concluirRecuperacao = {
  tags: etiqueta,
  operationId: 'concluirRecuperacao',
  summary: 'Escolher a palavra-passe nova (com o código do link)',
  description:
    'O código vem no link do email (#/recuperar?codigo=...). Só serve uma vez: depois de a palavra-passe mudar, ' +
    'o mesmo link deixa de funcionar.',
  security: [], // pública: quem a usa ainda não conseguiu entrar
  body: {
    type: 'object',
    properties: {
      codigo: { type: 'string', minLength: 1 },
      password_nova: palavraPasseNova,
    },
    required: ['codigo', 'password_nova'],
    additionalProperties: false,
  },
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400),
  },
};
