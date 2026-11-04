import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../autenticacao.ts';
import { bd } from '../db.ts';

// Rotas dos clientes (clínicas).
// Ler: vista vw_cliente. Criar, alterar e desativar: função fn_cliente_crud.
// O Administrador gere todas as clínicas. Uma clínica só vê os seus dados;
// para os mudar, faz um pedido de alteração (rotas de alteracoes-cliente.ts).

// O que o frontend envia no corpo do pedido (POST e PUT)
interface DadosCliente {
  nome?: string;
  nif?: string;
  morada_faturacao?: string;
  email?: string;
  telefone?: string;
  ativo?: boolean;
}

export async function rotasClientes(app: FastifyInstance) {
  // GET /api/clientes: lista todas as clínicas
  app.get('/api/clientes', { preHandler: exigirCargo('Administrador') }, async () => {
    const resultado = await bd.query('SELECT * FROM vw_cliente ORDER BY nome');
    return resultado.rows;
  });

  // GET /api/clientes/1: mostra uma clínica (uma clínica só pode ver a sua)
  app.get('/api/clientes/:id', { preHandler: exigirCargo('Administrador', 'Cliente') }, async (request, reply) => {
    const { id } = request.params as { id: string };
    // Uma clínica a pedir os dados de outra recebe 404, como se não existisse.
    if (request.user.cargo === 'Cliente' && Number(id) !== request.user.cliente_id) {
      return reply.code(404).send({ erro: 'O cliente não existe.' });
    }
    const resultado = await bd.query('SELECT * FROM vw_cliente WHERE id = $1', [id]);
    if (resultado.rows.length === 0) {
      return reply.code(404).send({ erro: 'O cliente não existe.' });
    }
    return resultado.rows[0];
  });

  // POST /api/clientes com { "nome": "...", "nif": "...", ... }: cria uma clínica (sem conta de acesso)
  app.post('/api/clientes', { preHandler: exigirCargo('Administrador') }, async (request, reply) => {
    const dados = request.body as DadosCliente | undefined;
    const resultado = await bd.query(
      `SELECT fn_cliente_crud(
         p_operacao         => 'CREATE',
         p_id               => NULL,
         p_nome             => $1,
         p_nif              => $2,
         p_morada_faturacao => $3,
         p_email            => $4,
         p_telefone         => $5
       ) AS id`,
      [dados?.nome, dados?.nif, dados?.morada_faturacao, dados?.email, dados?.telefone],
    );
    return reply.code(201).send(resultado.rows[0]);
  });

  // PUT /api/clientes/1 com os campos a mudar: altera uma clínica
  // "ativo": false desativa a clínica e as contas dela; "ativo": true reativa tudo.
  app.put('/api/clientes/:id', { preHandler: exigirCargo('Administrador') }, async (request) => {
    const { id } = request.params as { id: string };
    const dados = request.body as DadosCliente | undefined;
    const resultado = await bd.query(
      `SELECT fn_cliente_crud(
         p_operacao         => 'UPDATE',
         p_id               => $1,
         p_nome             => $2,
         p_nif              => $3,
         p_morada_faturacao => $4,
         p_email            => $5,
         p_telefone         => $6,
         p_ativo            => $7
       ) AS id`,
      [id, dados?.nome, dados?.nif, dados?.morada_faturacao, dados?.email, dados?.telefone, dados?.ativo],
    );
    return resultado.rows[0];
  });

  // DELETE /api/clientes/1: desativa a clínica e as contas dela (não apaga: há o histórico das ordens)
  app.delete('/api/clientes/:id', { preHandler: exigirCargo('Administrador') }, async (request) => {
    const { id } = request.params as { id: string };
    const resultado = await bd.query("SELECT fn_cliente_crud('DELETE', $1) AS id", [id]);
    return resultado.rows[0];
  });
}
