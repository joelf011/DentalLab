import { palavraPasseNova, respostaCriado, respostaId, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas da conta: registo de uma clínica e palavra-passe (ver comum/esquemas.ts)

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
