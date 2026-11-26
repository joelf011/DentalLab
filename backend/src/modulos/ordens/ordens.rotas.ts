import type { FastifyInstance } from 'fastify';
import { exigirCargo, exigirLogin } from '../../comum/acesso.ts';
import { bd, escreverComo, transacaoComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import {
  aceitarOrdem,
  alterarOrdem,
  criarOrdem,
  esquemaOrdem,
  esquemaTrabalho,
  listarOrdens,
  mudarEstadoOrdem,
  obterOrdem,
} from './ordens.esquemas.ts';

// Rotas das ordens de trabalho: as "encomendas" que a clínica envia ao laboratório.
// Uma ordem é um paciente com um ou mais trabalhos (ex.: uma coroa e uma ponte).
// Ler: vistas vw_ordem_trabalho e vw_trabalho.
// Escrever: fn_ordem_trabalho_crud, fn_trabalho_crud, pr_aceitar_ordem e pr_mudar_estado_ordem.
// A clínica só vê as suas ordens, e nunca as etapas de produção (são internas do laboratório).
// As regras dos dados estão em ordens.esquemas.ts.

// Os dados do paciente e da ordem (POST e PATCH)
interface DadosOrdem {
  nome_medico_responsavel?: string;
  nome_paciente?: string;
  sexo_paciente?: string;
  idade_paciente?: number;
  data_proxima_consulta?: string;
  observacoes?: string;
  prazo_entrega?: string;
}

// Um trabalho da encomenda nova
interface TrabalhoNovo {
  tipo_trabalho_id: number;
  natureza: string;
  cor?: string;
  dentes: number[];
}

// A encomenda nova: a ordem e os seus trabalhos
interface DadosEncomenda extends DadosOrdem {
  cliente_id?: number;
  trabalhos: TrabalhoNovo[];
}

// Junta a cada ordem os seus trabalhos (vista vw_trabalho), com uma só consulta para todas as ordens.
// Para a clínica, a etapa_atual vai a null: as etapas de produção são internas do laboratório.
async function juntarTrabalhos(ordens: Record<string, unknown>[], eClinica: boolean) {
  if (ordens.length === 0) {
    return ordens;
  }
  const ids = ordens.map((ordem) => ordem.id);
  const resultado = await bd.query('SELECT * FROM vw_trabalho WHERE ordem_trabalho_id = ANY($1) ORDER BY id', [ids]);
  for (const ordem of ordens) {
    ordem.trabalhos = resultado.rows
      .filter((trabalho) => trabalho.ordem_trabalho_id === ordem.id)
      .map((trabalho) => (eClinica ? { ...trabalho, etapa_atual: null } : trabalho));
  }
  return ordens;
}

export async function rotasOrdens(app: FastifyInstance) {
  // Esquemas com nome, usados pelas respostas das leituras
  app.addSchema(esquemaTrabalho);
  app.addSchema(esquemaOrdem);

  const laboratorio = exigirCargo('Administrador', 'Colaborador');

  // GET /api/v1/ordens: a clínica vê as suas; o laboratório vê todas
  // GET /api/v1/ordens?estado=Em%20avaliação: só as ordens nesse estado
  app.get('/ordens', { schema: listarOrdens, preHandler: exigirLogin }, async (request) => {
    const { estado } = request.query as { estado?: string };
    const eClinica = request.user.cargo === 'Cliente';
    // "$1 IS NULL OR ..." quer dizer: se o filtro não vier, não filtra.
    const resultado = await bd.query(
      `SELECT * FROM vw_ordem_trabalho
       WHERE ($1::bigint IS NULL OR cliente_id = $1)
         AND ($2::text IS NULL OR estado = $2)
       ORDER BY data_criacao DESC`,
      [eClinica ? request.user.cliente_id : null, estado ?? null],
    );
    return juntarTrabalhos(resultado.rows, eClinica);
  });

  // GET /api/v1/ordens/1: uma ordem, com os seus trabalhos
  app.get('/ordens/:id', { schema: obterOrdem, preHandler: exigirLogin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const eClinica = request.user.cargo === 'Cliente';
    const resultado = await bd.query('SELECT * FROM vw_ordem_trabalho WHERE id = $1', [id]);
    const ordem = resultado.rows[0];
    // Ordem que não existe, ou de outra clínica: 404 nos dois casos.
    if (!ordem || (eClinica && ordem.cliente_id !== request.user.cliente_id)) {
      return enviarErro(reply, 404, 'A ordem de trabalho não existe.');
    }
    const [comTrabalhos] = await juntarTrabalhos([ordem], eClinica);
    return comTrabalhos;
  });

  // POST /api/v1/ordens: cria a encomenda (a ordem e os seus trabalhos, tudo de uma vez)
  app.post('/ordens', { schema: criarOrdem, preHandler: exigirCargo('Cliente', 'Administrador') }, async (request, reply) => {
    const dados = request.body as DadosEncomenda;

    // A clínica cria para si própria; o Administrador indica para que clínica é.
    let clienteId: number | null;
    if (request.user.cargo === 'Cliente') {
      if (dados.cliente_id !== undefined && dados.cliente_id !== request.user.cliente_id) {
        return enviarErro(reply, 403, 'Uma clínica só pode criar encomendas para si própria.');
      }
      clienteId = request.user.cliente_id;
    } else {
      if (dados.cliente_id === undefined) {
        return enviarErro(reply, 400, 'Indique o cliente_id da clínica.');
      }
      clienteId = dados.cliente_id;
    }

    // Tudo numa transação: se um trabalho tiver um erro, a ordem também não fica gravada.
    const idOrdem = await transacaoComo(request.user.id, async (escrever) => {
      const ordem = await escrever(
        `SELECT fn_ordem_trabalho_crud(
           p_operacao                => 'CREATE',
           p_id                      => NULL,
           p_cliente_id              => $1,
           p_criado_por              => $2,
           p_nome_medico_responsavel => $3,
           p_nome_paciente           => $4,
           p_sexo_paciente           => $5,
           p_idade_paciente          => $6,
           p_data_proxima_consulta   => $7,
           p_observacoes             => $8
         ) AS id`,
        [
          clienteId,
          request.user.id,
          dados.nome_medico_responsavel,
          dados.nome_paciente,
          dados.sexo_paciente,
          dados.idade_paciente,
          dados.data_proxima_consulta,
          dados.observacoes,
        ],
      );
      const id = ordem.rows[0].id;
      // Cada trabalho recebe as etapas do seu tipo (a fn_trabalho_crud copia-as)
      for (const trabalho of dados.trabalhos) {
        await escrever(
          `SELECT fn_trabalho_crud(
             p_operacao          => 'CREATE',
             p_id                => NULL,
             p_ordem_trabalho_id => $1,
             p_tipo_trabalho_id  => $2,
             p_natureza          => $3,
             p_cor               => $4,
             p_dentes            => $5
           ) AS id`,
          [id, trabalho.tipo_trabalho_id, trabalho.natureza, trabalho.cor, trabalho.dentes],
        );
      }
      return id;
    });
    return enviarCriado(reply, 'ordens', idOrdem);
  });

  // PATCH /api/v1/ordens/1: o Administrador altera os dados da ordem (só os campos que vierem)
  app.patch('/ordens/:id', { schema: alterarOrdem, preHandler: exigirCargo('Administrador') }, async (request) => {
    const { id } = request.params as { id: number };
    const dados = request.body as DadosOrdem;
    const resultado = await escreverComo(
      request.user.id,
      `SELECT fn_ordem_trabalho_crud(
         p_operacao                => 'UPDATE',
         p_id                      => $1,
         p_nome_medico_responsavel => $2,
         p_nome_paciente           => $3,
         p_sexo_paciente           => $4,
         p_idade_paciente          => $5,
         p_data_proxima_consulta   => $6,
         p_observacoes             => $7,
         p_prazo_entrega           => $8
       ) AS id`,
      [
        id,
        dados.nome_medico_responsavel,
        dados.nome_paciente,
        dados.sexo_paciente,
        dados.idade_paciente,
        dados.data_proxima_consulta,
        dados.observacoes,
        dados.prazo_entrega,
      ],
    );
    return resultado.rows[0];
  });

  // POST /api/v1/ordens/1/aceitar com { "prazo_entrega": "2026-12-20" }: o laboratório aceita a ordem
  app.post('/ordens/:id/aceitar', { schema: aceitarOrdem, preHandler: laboratorio }, async (request) => {
    const { id } = request.params as { id: number };
    const { prazo_entrega } = request.body as { prazo_entrega: string };
    await escreverComo(request.user.id, 'CALL pr_aceitar_ordem($1, $2, $3)', [id, request.user.id, prazo_entrega]);
    return { id };
  });

  // POST /api/v1/ordens/1/estado com { "estado": "Em espera", "motivo": "..." }: muda o estado da ordem
  app.post('/ordens/:id/estado', { schema: mudarEstadoOrdem, preHandler: laboratorio }, async (request) => {
    const { id } = request.params as { id: number };
    const { estado, motivo } = request.body as { estado: string; motivo?: string };
    await escreverComo(request.user.id, 'CALL pr_mudar_estado_ordem($1, $2, $3, $4)', [
      id,
      request.user.id,
      estado,
      motivo ?? null,
    ]);
    return { id };
  });
}
