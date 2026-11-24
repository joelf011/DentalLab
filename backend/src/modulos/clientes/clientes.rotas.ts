import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import {
  alterarCliente,
  criarCliente,
  desativarCliente,
  esquemaCliente,
  listarClientes,
  obterCliente,
} from './clientes.esquemas.ts';

// Rotas dos clientes (clínicas).
// Ler: vista vw_cliente. Criar, alterar e desativar: função fn_cliente_crud.
// O Administrador gere todas as clínicas. Uma clínica só vê os seus dados;
// para os mudar, faz um pedido de alteração (módulo alteracoes-cliente).
// As regras dos dados (obrigatórios, tamanhos, NIF) estão em clientes.esquemas.ts.

// O que o frontend envia no corpo do pedido (POST e PATCH)
interface DadosCliente {
  nome?: string;
  nif?: string;
  morada_faturacao?: string;
  email?: string;
  telefone?: string;
  ativo?: boolean;
}

export async function rotasClientes(app: FastifyInstance) {
  // Esquema com nome, usado pelas respostas das leituras
  app.addSchema(esquemaCliente);

  // GET /api/v1/clientes: lista todas as clínicas
  app.get('/clientes', { schema: listarClientes, preHandler: exigirCargo('Administrador') }, async () => {
    const resultado = await bd.query('SELECT * FROM vw_cliente ORDER BY nome');
    return resultado.rows;
  });

  // GET /api/v1/clientes/1: mostra uma clínica (uma clínica só pode ver a sua)
  app.get('/clientes/:id', { schema: obterCliente, preHandler: exigirCargo('Administrador', 'Cliente') }, async (request, reply) => {
    const { id } = request.params as { id: number };
    // Uma clínica a pedir os dados de outra recebe 404, como se não existisse.
    if (request.user.cargo === 'Cliente' && id !== request.user.cliente_id) {
      return enviarErro(reply, 404, 'O cliente não existe.');
    }
    const resultado = await bd.query('SELECT * FROM vw_cliente WHERE id = $1', [id]);
    if (resultado.rows.length === 0) {
      return enviarErro(reply, 404, 'O cliente não existe.');
    }
    return resultado.rows[0];
  });

  // POST /api/v1/clientes com { "nome": "...", "nif": "...", ... }: cria uma clínica (sem conta de acesso)
  app.post('/clientes', { schema: criarCliente, preHandler: exigirCargo('Administrador') }, async (request, reply) => {
    const dados = request.body as DadosCliente;
    const resultado = await escreverComo(
      request.user.id,
      `SELECT fn_cliente_crud(
         p_operacao         => 'CREATE',
         p_id               => NULL,
         p_nome             => $1,
         p_nif              => $2,
         p_morada_faturacao => $3,
         p_email            => $4,
         p_telefone         => $5
       ) AS id`,
      [dados.nome, dados.nif, dados.morada_faturacao, dados.email, dados.telefone],
    );
    return enviarCriado(reply, 'clientes', resultado.rows[0].id);
  });

  // PATCH /api/v1/clientes/1 com os campos a mudar: altera uma clínica (os que não vêm ficam como estão)
  // "ativo": false desativa a clínica e as contas dela; "ativo": true reativa tudo.
  app.patch('/clientes/:id', { schema: alterarCliente, preHandler: exigirCargo('Administrador') }, async (request) => {
    const { id } = request.params as { id: number };
    const dados = request.body as DadosCliente;
    const resultado = await escreverComo(
      request.user.id,
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
      [id, dados.nome, dados.nif, dados.morada_faturacao, dados.email, dados.telefone, dados.ativo],
    );
    return resultado.rows[0];
  });

  // DELETE /api/v1/clientes/1: desativa a clínica e as contas dela (não apaga: há o histórico das ordens)
  // Responde 204: correu bem e não há nada para devolver.
  app.delete('/clientes/:id', { schema: desativarCliente, preHandler: exigirCargo('Administrador') }, async (request, reply) => {
    const { id } = request.params as { id: number };
    await escreverComo(request.user.id, "SELECT fn_cliente_crud('DELETE', $1) AS id", [id]);
    return reply.code(204).send();
  });
}
