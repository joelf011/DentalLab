import type { FastifyInstance } from 'fastify';
import { bd } from '../db.ts';

// Rotas dos cargos (Administrador, Colaborador, Cliente).
// Ler: vista vw_cargo. Criar, alterar e apagar: função fn_cargo_crud. As duas foram criadas no pgAdmin.
//
// Os valores vão sempre em $1, $2... e nunca colados no texto do SQL:
// assim ninguém consegue alterar o SQL através dos dados que envia (SQL injection).

// O que o frontend envia no corpo do pedido (POST e PUT)
interface DadosCargo {
  designacao?: string;
}

export async function rotasCargos(app: FastifyInstance) {
  // GET /api/cargos: lista todos os cargos
  app.get('/api/cargos', async () => {
    const resultado = await bd.query('SELECT * FROM vw_cargo ORDER BY id');
    return resultado.rows;
  });

  // GET /api/cargos/1: mostra um cargo
  app.get('/api/cargos/:id', async (request, reply) => {
    const { id } = request.params as { id: string };
    const resultado = await bd.query('SELECT * FROM vw_cargo WHERE id = $1', [id]);
    if (resultado.rows.length === 0) {
      return reply.code(404).send({ erro: 'O cargo não existe.' });
    }
    return resultado.rows[0];
  });

  // POST /api/cargos com { "designacao": "Técnico" }: cria um cargo e devolve o id novo
  app.post('/api/cargos', async (request, reply) => {
    const dados = request.body as DadosCargo | undefined;
    const resultado = await bd.query("SELECT fn_cargo_crud('CREATE', NULL, $1) AS id", [dados?.designacao]);
    return reply.code(201).send(resultado.rows[0]);
  });

  // PUT /api/cargos/1 com { "designacao": "Técnico" }: altera um cargo
  app.put('/api/cargos/:id', async (request) => {
    const { id } = request.params as { id: string };
    const dados = request.body as DadosCargo | undefined;
    const resultado = await bd.query("SELECT fn_cargo_crud('UPDATE', $1, $2) AS id", [id, dados?.designacao]);
    return resultado.rows[0];
  });

  // DELETE /api/cargos/1: apaga um cargo (a função recusa se o cargo tiver utilizadores)
  app.delete('/api/cargos/:id', async (request) => {
    const { id } = request.params as { id: string };
    const resultado = await bd.query("SELECT fn_cargo_crud('DELETE', $1) AS id", [id]);
    return resultado.rows[0];
  });
}
