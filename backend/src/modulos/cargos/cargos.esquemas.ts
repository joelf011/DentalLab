import { resposta, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas dos cargos (ver comum/esquemas.ts)

// Um cargo, tal como vem da vista vw_cargo.
// Tem nome ($id), por isso regista-se no módulo (app.addSchema) e as rotas usam { $ref: 'Cargo#' }.
export const esquemaCargo = {
  $id: 'Cargo',
  type: 'object',
  properties: {
    id: { type: 'integer' },
    designacao: { type: 'string', examples: ['Colaborador'] },
  },
  required: ['id', 'designacao'],
};

// GET /api/v1/cargos
export const listarCargos = {
  tags: ['Cargos'],
  operationId: 'listarCargos',
  summary: 'Listar os cargos',
  description:
    'Qualquer pessoa com login. Os cargos são fixos (Administrador, Colaborador e Cliente); ' +
    'o backoffice usa esta lista para escolher o cargo_id de uma conta.',
  response: {
    200: resposta('Os cargos, por id.', { type: 'array', items: { $ref: 'Cargo#' } }),
    ...respostasErro(401),
  },
};
