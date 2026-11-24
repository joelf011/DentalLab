import { resposta, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas da saúde (ver comum/esquemas.ts)

// GET /api/v1/saude
export const verificarSaude = {
  tags: ['Saúde'],
  operationId: 'verificarSaude',
  summary: 'Verificar a API e a ligação à base de dados',
  security: [], // pública: não precisa de login
  response: {
    200: resposta(
      'A API e a base de dados estão a funcionar.',
      {
        type: 'object',
        properties: {
          api: { type: 'string', enum: ['ok'] },
          bd: { type: 'string', enum: ['ok'] },
        },
        required: ['api', 'bd'],
      },
      'no-store',
    ),
    ...respostasErro(503),
  },
};
