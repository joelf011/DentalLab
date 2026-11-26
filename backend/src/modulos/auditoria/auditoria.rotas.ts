import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../../comum/acesso.ts';
import { bd } from '../../comum/bd.ts';
import { listarAtividades } from './auditoria.esquemas.ts';

// Rotas do Registo de Atividades (só o Administrador).
// A auditoria é preenchida sozinha pelo trigger fn_trg_auditoria, em cada alteração das tabelas principais;
// a API só a lê, da vista vw_registo_auditoria (que junta o autor e uma descrição em português).

// Os filtros da lista
interface FiltrosAtividades {
  pagina: number;
  tamanho: number;
  de?: string;
  ate?: string;
  utilizador_id?: number;
  entidade?: string;
  pesquisa?: string;
}

export async function rotasAuditoria(app: FastifyInstance) {
  // GET /api/v1/auditoria?pagina=1&tamanho=50&de=2026-11-01&pesquisa=ordem
  app.get('/auditoria', { schema: listarAtividades, preHandler: exigirCargo('Administrador') }, async (request) => {
    const filtros = request.query as FiltrosAtividades;

    // As mesmas condições servem para contar o total e para buscar a página.
    // "$1 IS NULL OR ..." quer dizer: se o filtro não vier, não filtra.
    // O "ate" inclui o dia todo: até ao início do dia seguinte.
    const condicoes = `
      WHERE ($1::date IS NULL OR data_hora >= $1::date)
        AND ($2::date IS NULL OR data_hora < $2::date + 1)
        AND ($3::bigint IS NULL OR utilizador_id = $3)
        AND ($4::text IS NULL OR entidade_afetada = $4)
        AND ($5::text IS NULL OR descricao ILIKE '%' || $5 || '%' OR autor ILIKE '%' || $5 || '%')`;
    const valores = [
      filtros.de ?? null,
      filtros.ate ?? null,
      filtros.utilizador_id ?? null,
      filtros.entidade ?? null,
      filtros.pesquisa ?? null,
    ];

    const total = await bd.query(`SELECT count(*) AS total FROM vw_registo_auditoria ${condicoes}`, valores);
    const pagina = await bd.query(
      `SELECT * FROM vw_registo_auditoria ${condicoes}
       ORDER BY data_hora DESC, id DESC
       LIMIT $6 OFFSET $7`,
      [...valores, filtros.tamanho, (filtros.pagina - 1) * filtros.tamanho],
    );
    return {
      pagina: filtros.pagina,
      tamanho_pagina: filtros.tamanho,
      total: total.rows[0].total,
      itens: pagina.rows,
    };
  });
}
