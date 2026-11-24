import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import { alterarEtapa, criarEtapa, desativarEtapa, esquemaEtapa, listarEtapas } from './etapas.esquemas.ts';

// Rotas das etapas de produção do catálogo (Modelos em gesso, Fresagem...). Todas são do Administrador.
// Ler: vista vw_etapa. Criar, alterar e desativar: função fn_etapa_crud.
// A ordem das etapas de cada tipo de trabalho define-se no módulo tipos-trabalho.
// As regras dos dados estão em etapas.esquemas.ts.

// O que o Administrador envia (POST e PATCH)
interface DadosEtapa {
  nome?: string;
  descricao?: string;
  ativa?: boolean;
}

export async function rotasEtapas(app: FastifyInstance) {
  // Esquema com nome, usado pela resposta da lista
  app.addSchema(esquemaEtapa);

  const soAdmin = exigirCargo('Administrador');

  // GET /api/v1/etapas: lista todas as etapas (também as desativadas)
  app.get('/etapas', { schema: listarEtapas, preHandler: soAdmin }, async () => {
    const resultado = await bd.query('SELECT * FROM vw_etapa ORDER BY nome');
    return resultado.rows;
  });

  // POST /api/v1/etapas: cria uma etapa
  app.post('/etapas', { schema: criarEtapa, preHandler: soAdmin }, async (request, reply) => {
    const dados = request.body as DadosEtapa;
    const resultado = await escreverComo(
      request.user.id,
      "SELECT fn_etapa_crud('CREATE', NULL, p_nome => $1, p_descricao => $2) AS id",
      [dados.nome, dados.descricao],
    );
    return enviarCriado(reply, 'etapas', resultado.rows[0].id);
  });

  // PATCH /api/v1/etapas/1: altera uma etapa (só os campos que vierem)
  app.patch('/etapas/:id', { schema: alterarEtapa, preHandler: soAdmin }, async (request) => {
    const { id } = request.params as { id: number };
    const dados = request.body as DadosEtapa;
    const resultado = await escreverComo(
      request.user.id,
      "SELECT fn_etapa_crud('UPDATE', $1, p_nome => $2, p_descricao => $3, p_ativa => $4) AS id",
      [id, dados.nome, dados.descricao, dados.ativa],
    );
    return resultado.rows[0];
  });

  // DELETE /api/v1/etapas/1: desativa a etapa (não apaga)
  app.delete('/etapas/:id', { schema: desativarEtapa, preHandler: soAdmin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    await escreverComo(request.user.id, "SELECT fn_etapa_crud('DELETE', $1) AS id", [id]);
    return reply.code(204).send();
  });
}
