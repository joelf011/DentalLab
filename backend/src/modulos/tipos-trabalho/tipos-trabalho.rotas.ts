import type { FastifyInstance } from 'fastify';
import { exigirCargo, exigirLogin } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import {
  alterarTipoTrabalho,
  criarTipoTrabalho,
  definirEtapasDoTipo,
  desativarTipoTrabalho,
  esquemaTipoTrabalho,
  listarEtapasDoTipo,
  listarTiposTrabalho,
} from './tipos-trabalho.esquemas.ts';

// Rotas dos tipos de trabalho (catálogo do laboratório: Coroa, Ponte...) e das etapas de cada tipo.
// Ler: vistas vw_tipo_trabalho e vw_etapa_tipo_trabalho.
// Escrever: função fn_tipo_trabalho_crud e procedimento pr_definir_etapas_tipo_trabalho.
// As regras dos dados estão em tipos-trabalho.esquemas.ts.

// O que o Administrador envia (POST e PATCH)
interface DadosTipoTrabalho {
  nome?: string;
  descricao?: string;
  ativo?: boolean;
}

export async function rotasTiposTrabalho(app: FastifyInstance) {
  // Esquema com nome, usado pela resposta da lista
  app.addSchema(esquemaTipoTrabalho);

  const soAdmin = exigirCargo('Administrador');

  // GET /api/v1/tipos-trabalho: o Administrador vê todos; os outros, só os ativos
  app.get('/tipos-trabalho', { schema: listarTiposTrabalho, preHandler: exigirLogin }, async (request) => {
    const todos = request.user.cargo === 'Administrador';
    const resultado = await bd.query('SELECT * FROM vw_tipo_trabalho WHERE $1 OR ativo ORDER BY nome', [todos]);
    return resultado.rows;
  });

  // POST /api/v1/tipos-trabalho: cria um tipo de trabalho
  app.post('/tipos-trabalho', { schema: criarTipoTrabalho, preHandler: soAdmin }, async (request, reply) => {
    const dados = request.body as DadosTipoTrabalho;
    const resultado = await escreverComo(
      request.user.id,
      "SELECT fn_tipo_trabalho_crud('CREATE', NULL, p_nome => $1, p_descricao => $2) AS id",
      [dados.nome, dados.descricao],
    );
    return enviarCriado(reply, 'tipos-trabalho', resultado.rows[0].id);
  });

  // PATCH /api/v1/tipos-trabalho/1: altera um tipo de trabalho (só os campos que vierem)
  app.patch('/tipos-trabalho/:id', { schema: alterarTipoTrabalho, preHandler: soAdmin }, async (request) => {
    const { id } = request.params as { id: number };
    const dados = request.body as DadosTipoTrabalho;
    const resultado = await escreverComo(
      request.user.id,
      "SELECT fn_tipo_trabalho_crud('UPDATE', $1, p_nome => $2, p_descricao => $3, p_ativo => $4) AS id",
      [id, dados.nome, dados.descricao, dados.ativo],
    );
    return resultado.rows[0];
  });

  // DELETE /api/v1/tipos-trabalho/1: desativa (não apaga: os trabalhos antigos continuam a referi-lo)
  app.delete('/tipos-trabalho/:id', { schema: desativarTipoTrabalho, preHandler: soAdmin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    await escreverComo(request.user.id, "SELECT fn_tipo_trabalho_crud('DELETE', $1) AS id", [id]);
    return reply.code(204).send();
  });

  // GET /api/v1/tipos-trabalho/1/etapas: as etapas deste tipo, pela ordem
  // A clínica não vê as etapas de produção (são internas do laboratório).
  app.get(
    '/tipos-trabalho/:id/etapas',
    { schema: listarEtapasDoTipo, preHandler: exigirCargo('Administrador', 'Colaborador') },
    async (request, reply) => {
      const { id } = request.params as { id: number };
      const tipo = await bd.query('SELECT id FROM vw_tipo_trabalho WHERE id = $1', [id]);
      if (tipo.rows.length === 0) {
        return enviarErro(reply, 404, 'O tipo de trabalho não existe.');
      }
      const resultado = await bd.query(
        'SELECT ordem, etapa_id, nome FROM vw_etapa_tipo_trabalho WHERE tipo_trabalho_id = $1 ORDER BY ordem',
        [id],
      );
      return resultado.rows;
    },
  );

  // PUT /api/v1/tipos-trabalho/1/etapas com { "etapas": [3, 1, 5] }: substitui a lista inteira
  // É PUT (e não PATCH) porque a lista enviada substitui a anterior por completo.
  app.put('/tipos-trabalho/:id/etapas', { schema: definirEtapasDoTipo, preHandler: soAdmin }, async (request) => {
    const { id } = request.params as { id: number };
    const { etapas } = request.body as { etapas: number[] };
    await escreverComo(request.user.id, 'CALL pr_definir_etapas_tipo_trabalho($1, $2)', [id, etapas]);
    return { id };
  });
}
