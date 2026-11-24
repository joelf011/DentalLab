import { paramId, respostaId, respostasErro } from '../../comum/esquemas.ts';
import { camposTrabalho } from '../ordens/ordens.esquemas.ts';

// Esquemas das rotas dos trabalhos (ver comum/esquemas.ts)

const etiqueta = ['Trabalhos'];

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
