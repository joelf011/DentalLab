import type { FastifyInstance } from 'fastify';
import { exigirLogin } from '../../comum/acesso.ts';
import { bd } from '../../comum/bd.ts';
import { esquemaCargo, listarCargos } from './cargos.esquemas.ts';

// Rotas dos cargos: Administrador, Colaborador e Cliente.
// Os cargos são fixos: a API só os lista (vista vw_cargo). Se um dia mudarem, muda-se nos dados iniciais
// da BD (06_dados_iniciais.sql) e no código que depende deles (ex.: exigirCargo('Administrador')).

export async function rotasCargos(app: FastifyInstance) {
  // Esquema com nome, usado pela resposta da lista
  app.addSchema(esquemaCargo);

  // GET /api/v1/cargos: lista todos os cargos
  // O backoffice usa-a para escolher o cargo_id ao criar ou alterar uma conta.
  app.get('/cargos', { schema: listarCargos, preHandler: exigirLogin }, async () => {
    const resultado = await bd.query('SELECT * FROM vw_cargo ORDER BY id');
    return resultado.rows;
  });
}
