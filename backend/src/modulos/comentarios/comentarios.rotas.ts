import type { FastifyInstance } from 'fastify';
import { exigirCargo, exigirLogin, podeVerOrdem } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import {
  criarComentarioOrdem,
  criarNotaTrabalho,
  esquemaComentario,
  listarComentariosOrdem,
  listarNotasTrabalho,
} from './comentarios.esquemas.ts';

// Rotas dos comentários. Um comentário pertence a uma ordem ou a um trabalho:
// - ordem: a conversa entre a clínica e o laboratório (a clínica vê);
// - trabalho: notas internas do laboratório (a clínica nunca vê).
// Ler: vista vw_comentario. Escrever: fn_comentario_crud.
// As regras dos dados estão em comentarios.esquemas.ts.

export async function rotasComentarios(app: FastifyInstance) {
  // Esquema com nome, usado pelas respostas
  app.addSchema(esquemaComentario);

  const laboratorio = exigirCargo('Administrador', 'Colaborador');

  // Lê um comentário acabado de criar (a resposta do POST)
  async function lerComentario(id: number) {
    const resultado = await bd.query('SELECT * FROM vw_comentario WHERE id = $1', [id]);
    return resultado.rows[0];
  }

  // GET /api/v1/ordens/1/comentarios: a conversa da ordem
  app.get('/ordens/:id/comentarios', { schema: listarComentariosOrdem, preHandler: exigirLogin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    if (!(await podeVerOrdem(request.user, id))) {
      return enviarErro(reply, 404, 'A ordem de trabalho não existe.');
    }
    const resultado = await bd.query(
      'SELECT * FROM vw_comentario WHERE ordem_trabalho_id = $1 ORDER BY data_criacao',
      [id],
    );
    return resultado.rows;
  });

  // POST /api/v1/ordens/1/comentarios com { "conteudo": "..." }: escreve na conversa da ordem
  app.post('/ordens/:id/comentarios', { schema: criarComentarioOrdem, preHandler: exigirLogin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const { conteudo } = request.body as { conteudo: string };
    if (!(await podeVerOrdem(request.user, id))) {
      return enviarErro(reply, 404, 'A ordem de trabalho não existe.');
    }
    const resultado = await escreverComo(
      request.user.id,
      "SELECT fn_comentario_crud('CREATE', NULL, p_ordem_trabalho_id => $1, p_utilizador_id => $2, p_conteudo => $3) AS id",
      [id, request.user.id, conteudo],
    );
    return reply.code(201).send(await lerComentario(resultado.rows[0].id));
  });

  // GET /api/v1/trabalhos/1/notas: as notas internas do trabalho
  app.get('/trabalhos/:id/notas', { schema: listarNotasTrabalho, preHandler: laboratorio }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const trabalho = await bd.query('SELECT id FROM vw_trabalho WHERE id = $1', [id]);
    if (trabalho.rows.length === 0) {
      return enviarErro(reply, 404, 'O trabalho não existe.');
    }
    const resultado = await bd.query('SELECT * FROM vw_comentario WHERE trabalho_id = $1 ORDER BY data_criacao', [id]);
    return resultado.rows;
  });

  // POST /api/v1/trabalhos/1/notas com { "conteudo": "..." }: escreve uma nota interna
  app.post('/trabalhos/:id/notas', { schema: criarNotaTrabalho, preHandler: laboratorio }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const { conteudo } = request.body as { conteudo: string };
    // Se o trabalho não existir, a função responde 404 (no_data_found)
    const resultado = await escreverComo(
      request.user.id,
      "SELECT fn_comentario_crud('CREATE', NULL, p_trabalho_id => $1, p_utilizador_id => $2, p_conteudo => $3) AS id",
      [id, request.user.id, conteudo],
    );
    return reply.code(201).send(await lerComentario(resultado.rows[0].id));
  });
}
