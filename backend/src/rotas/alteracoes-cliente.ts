import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../autenticacao.ts';
import { bd } from '../db.ts';

// Rotas dos pedidos de alteração dos dados de uma clínica.
// A clínica pede; o Administrador aprova (os dados passam para a clínica) ou rejeita (com motivo).
// Ler: vista vw_alteracao_cliente. Pedir: fn_pedir_alteracao_cliente. Decidir: fn_decidir_alteracao_cliente.

// O que a clínica envia ao pedir uma alteração (só os campos que quer mudar)
interface DadosPedido {
  nome?: string;
  morada_faturacao?: string;
  email?: string;
  telefone?: string;
}

export async function rotasAlteracoesCliente(app: FastifyInstance) {
  // POST /api/alteracoes-cliente: a clínica pede para alterar os seus dados
  app.post('/api/alteracoes-cliente', { preHandler: exigirCargo('Cliente') }, async (request, reply) => {
    const dados = request.body as DadosPedido | undefined;
    const resultado = await bd.query(
      `SELECT fn_pedir_alteracao_cliente(
         p_cliente_id       => $1,
         p_pedido_por       => $2,
         p_nome             => $3,
         p_morada_faturacao => $4,
         p_email            => $5,
         p_telefone         => $6
       ) AS id`,
      [request.user.cliente_id, request.user.id, dados?.nome, dados?.morada_faturacao, dados?.email, dados?.telefone],
    );
    return reply.code(201).send(resultado.rows[0]);
  });

  // GET /api/alteracoes-cliente: lista os pedidos (os mais recentes primeiro)
  // O Administrador vê todos; a clínica só os seus. ?estado=pendente mostra só os que estão à espera.
  app.get('/api/alteracoes-cliente', { preHandler: exigirCargo('Administrador', 'Cliente') }, async (request) => {
    const { estado } = request.query as { estado?: string };
    // Para a clínica filtra-se pelo cliente dela; para o Administrador fica null (= todos).
    const clienteId = request.user.cargo === 'Cliente' ? request.user.cliente_id : null;
    // "$1 IS NULL OR ..." quer dizer: se o filtro não vier, não filtra.
    const resultado = await bd.query(
      `SELECT * FROM vw_alteracao_cliente
       WHERE ($1::text IS NULL OR estado = $1)
         AND ($2::bigint IS NULL OR cliente_id = $2)
       ORDER BY data_pedido DESC`,
      [estado ?? null, clienteId],
    );
    return resultado.rows;
  });

  // GET /api/alteracoes-cliente/1: mostra um pedido (a clínica só pode ver os seus)
  app.get('/api/alteracoes-cliente/:id', { preHandler: exigirCargo('Administrador', 'Cliente') }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const resultado = await bd.query('SELECT * FROM vw_alteracao_cliente WHERE id = $1', [id]);
    const pedido = resultado.rows[0];
    // Pedido que não existe, ou de outra clínica: 404 nos dois casos.
    if (!pedido || (request.user.cargo === 'Cliente' && pedido.cliente_id !== request.user.cliente_id)) {
      return reply.code(404).send({ erro: 'O pedido de alteração não existe.' });
    }
    return pedido;
  });

  // POST /api/alteracoes-cliente/1/aprovar: o Administrador aprova; os dados novos passam para a clínica
  app.post('/api/alteracoes-cliente/:id/aprovar', { preHandler: exigirCargo('Administrador') }, async (request) => {
    const { id } = request.params as { id: string };
    const resultado = await bd.query(
      `SELECT fn_decidir_alteracao_cliente(
         p_id           => $1,
         p_decidido_por => $2,
         p_aprovar      => TRUE
       ) AS id`,
      [id, request.user.id],
    );
    return resultado.rows[0];
  });

  // POST /api/alteracoes-cliente/1/rejeitar com { "motivo_rejeicao": "..." }: o Administrador rejeita
  app.post('/api/alteracoes-cliente/:id/rejeitar', { preHandler: exigirCargo('Administrador') }, async (request) => {
    const { id } = request.params as { id: string };
    const dados = request.body as { motivo_rejeicao?: string } | undefined;
    const resultado = await bd.query(
      `SELECT fn_decidir_alteracao_cliente(
         p_id              => $1,
         p_decidido_por    => $2,
         p_aprovar         => FALSE,
         p_motivo_rejeicao => $3
       ) AS id`,
      [id, request.user.id, dados?.motivo_rejeicao],
    );
    return resultado.rows[0];
  });
}
