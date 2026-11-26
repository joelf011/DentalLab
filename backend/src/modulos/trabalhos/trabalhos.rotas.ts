import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../../comum/acesso.ts';
import { bd, escreverComo, transacaoComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import {
  alterarTrabalho,
  assumirEtapa,
  concluirEtapa,
  esquemaEtapaTrabalho,
  esquemaTrabalhoEmProducao,
  listarTrabalhos,
  obterTrabalho,
} from './trabalhos.esquemas.ts';

// Rotas dos trabalhos e da sua produção (cada trabalho pertence a uma ordem: ex.: a coroa de um paciente).
// Os trabalhos criam-se com a encomenda (POST /ordens), e cada um recebe as etapas do seu tipo.
// Ler: vistas vw_trabalho, vw_ordem_trabalho e vw_etapa_trabalho.
// Escrever: fn_trabalho_crud, fn_etapa_trabalho_crud, pr_iniciar_etapa, pr_concluir_etapa e pr_mudar_estado_ordem.
// Tudo isto é do laboratório: a clínica nunca vê as etapas de produção.
// As regras dos dados estão em trabalhos.esquemas.ts.

// O que o Administrador pode mudar num trabalho
interface DadosTrabalho {
  natureza?: string;
  cor?: string;
  dentes?: number[];
}

// O que se envia ao concluir uma etapa
interface DadosConclusao {
  atribuicao: 'livre' | 'eu' | 'outro';
  colaborador_id?: number;
  destino: 'avancar' | 'prova';
}

// Os trabalhos, com os dados da sua ordem (as duas vistas juntas pelo id da ordem)
const SQL_TRABALHOS = `
  SELECT t.*, o.cliente, o.nome_paciente, o.estado AS estado_ordem, o.prazo_entrega
  FROM vw_trabalho t
  JOIN vw_ordem_trabalho o ON o.id = t.ordem_trabalho_id`;

// Junta a cada trabalho as suas etapas, pela ordem (uma só consulta para todos os trabalhos)
async function juntarEtapas(trabalhos: Record<string, unknown>[]) {
  if (trabalhos.length === 0) {
    return trabalhos;
  }
  const ids = trabalhos.map((trabalho) => trabalho.id);
  const resultado = await bd.query('SELECT * FROM vw_etapa_trabalho WHERE trabalho_id = ANY($1) ORDER BY ordem', [ids]);
  for (const trabalho of trabalhos) {
    trabalho.etapas = resultado.rows.filter((etapa) => etapa.trabalho_id === trabalho.id);
  }
  return trabalhos;
}

// Uma etapa de um trabalho, com o id da ordem (para mudar o estado da ordem ao mandar para prova)
async function obterEtapa(id: number) {
  const resultado = await bd.query(
    `SELECT et.id, et.trabalho_id, et.ordem, et.responsavel_id, t.ordem_trabalho_id
     FROM vw_etapa_trabalho et
     JOIN vw_trabalho t ON t.id = et.trabalho_id
     WHERE et.id = $1`,
    [id],
  );
  return resultado.rows[0];
}

export async function rotasTrabalhos(app: FastifyInstance) {
  // Esquemas com nome, usados pelas respostas das leituras
  app.addSchema(esquemaEtapaTrabalho);
  app.addSchema(esquemaTrabalhoEmProducao);

  const laboratorio = exigirCargo('Administrador', 'Colaborador');

  // GET /api/v1/trabalhos: os trabalhos, com as etapas (os de prazo mais próximo primeiro)
  // GET /api/v1/trabalhos?abertos=true: só os das ordens que ainda não acabaram
  app.get('/trabalhos', { schema: listarTrabalhos, preHandler: laboratorio }, async (request) => {
    const { abertos } = request.query as { abertos?: boolean };
    const resultado = await bd.query(
      `${SQL_TRABALHOS}
       WHERE NOT $1 OR o.estado NOT IN ('Concluído', 'Entregue', 'Rejeitado')
       ORDER BY o.prazo_entrega NULLS LAST, t.id`,
      [abertos === true],
    );
    return juntarEtapas(resultado.rows);
  });

  // GET /api/v1/trabalhos/1: um trabalho, com as etapas
  app.get('/trabalhos/:id', { schema: obterTrabalho, preHandler: laboratorio }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const resultado = await bd.query(`${SQL_TRABALHOS} WHERE t.id = $1`, [id]);
    if (resultado.rows.length === 0) {
      return enviarErro(reply, 404, 'O trabalho não existe.');
    }
    const [trabalho] = await juntarEtapas(resultado.rows);
    return trabalho;
  });

  // PATCH /api/v1/trabalhos/1: o Administrador altera um trabalho (só os campos que vierem)
  app.patch('/trabalhos/:id', { schema: alterarTrabalho, preHandler: exigirCargo('Administrador') }, async (request) => {
    const { id } = request.params as { id: number };
    const dados = request.body as DadosTrabalho;
    const resultado = await escreverComo(
      request.user.id,
      `SELECT fn_trabalho_crud(
         p_operacao => 'UPDATE',
         p_id       => $1,
         p_natureza => $2,
         p_cor      => $3,
         p_dentes   => $4
       ) AS id`,
      [id, dados.natureza, dados.cor, dados.dentes],
    );
    return resultado.rows[0];
  });

  // POST /api/v1/etapas-trabalho/1/assumir: quem pede fica responsável e a etapa começa
  app.post('/etapas-trabalho/:id/assumir', { schema: assumirEtapa, preHandler: laboratorio }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const etapa = await obterEtapa(id);
    if (!etapa) {
      return enviarErro(reply, 404, 'A etapa não existe.');
    }
    // Uma etapa atribuída a outra pessoa fica reservada para ela (o Administrador pode sempre).
    const deOutro = etapa.responsavel_id !== null && etapa.responsavel_id !== request.user.id;
    if (deOutro && request.user.cargo !== 'Administrador') {
      return enviarErro(reply, 409, 'Esta etapa está atribuída a outra pessoa.');
    }
    // A BD confirma o resto: etapa anterior concluída, etapa ainda por começar, ordem em produção.
    await escreverComo(request.user.id, 'CALL pr_iniciar_etapa($1, $2)', [id, request.user.id]);
    return { id };
  });

  // POST /api/v1/etapas-trabalho/1/concluir com { "atribuicao": "livre", "destino": "avancar" }
  app.post('/etapas-trabalho/:id/concluir', { schema: concluirEtapa, preHandler: laboratorio }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const dados = request.body as DadosConclusao;
    const etapa = await obterEtapa(id);
    if (!etapa) {
      return enviarErro(reply, 404, 'A etapa não existe.');
    }
    if (request.user.cargo !== 'Administrador' && etapa.responsavel_id !== request.user.id) {
      return enviarErro(reply, 403, 'Só quem assumiu a etapa a pode concluir.');
    }
    if (dados.atribuicao === 'outro' && dados.colaborador_id === undefined) {
      return enviarErro(reply, 400, 'Indique o colaborador_id de quem fica com a etapa seguinte.');
    }

    // Tudo numa transação: concluir, atribuir a seguinte e (se for o caso) mandar a ordem para prova.
    await transacaoComo(request.user.id, async (escrever) => {
      await escrever('CALL pr_concluir_etapa($1, $2)', [id, request.user.id]);

      // A etapa seguinte do mesmo trabalho fica atribuída (sem começar), se não for "livre"
      if (dados.atribuicao !== 'livre') {
        const seguinte = await escrever(
          `SELECT id FROM vw_etapa_trabalho
           WHERE trabalho_id = $1 AND ordem > $2 AND data_conclusao IS NULL
           ORDER BY ordem LIMIT 1`,
          [etapa.trabalho_id, etapa.ordem],
        );
        if (seguinte.rows.length > 0) {
          const responsavel = dados.atribuicao === 'eu' ? request.user.id : dados.colaborador_id;
          // A fn_etapa_trabalho_crud confirma que o responsável é do laboratório e está ativo
          await escrever("SELECT fn_etapa_trabalho_crud('UPDATE', $1, p_responsavel_id => $2) AS id", [
            seguinte.rows[0].id,
            responsavel,
          ]);
        }
      }

      if (dados.destino === 'prova') {
        await escrever("CALL pr_mudar_estado_ordem($1, $2, 'Em prova')", [etapa.ordem_trabalho_id, request.user.id]);
      }
    });
    return { id };
  });
}
