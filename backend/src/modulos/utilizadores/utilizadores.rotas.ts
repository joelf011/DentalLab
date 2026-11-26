import bcrypt from 'bcryptjs';
import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import { configuracao } from '../../configuracao.ts';
import {
  alterarUtilizador,
  aprovarUtilizador,
  criarUtilizador,
  desativarUtilizador,
  esquemaUtilizador,
  listarColaboradores,
  listarUtilizadores,
  obterUtilizador,
} from './utilizadores.esquemas.ts';

// Rotas das contas de acesso (utilizadores). Todas são do Administrador, menos a lista de colaboradores.
// Ler: vista vw_utilizador (não mostra o password_hash).
// Criar, alterar e desativar: fn_utilizador_crud. Aprovar: fn_aprovar_utilizador.
// As contas criadas pelo Administrador ficam logo aprovadas, com uma palavra-passe temporária
// que a pessoa tem de mudar no primeiro login (PUT /api/v1/conta/palavra-passe).
// As regras dos dados (obrigatórios, tamanhos, palavra-passe) estão em utilizadores.esquemas.ts.

// O que o frontend envia para criar uma conta (POST)
interface DadosNovoUtilizador {
  nome: string;
  email: string;
  cargo_id: number;
  cliente_id?: number; // só para o cargo Cliente: a clínica a que a conta pertence
  password: string; // palavra-passe temporária
}

// O que o frontend envia para alterar uma conta (PATCH): só os campos que mudam
interface DadosUtilizador {
  nome?: string;
  email?: string;
  cargo_id?: number;
  cliente_id?: number;
  password?: string; // nova palavra-passe temporária
  ativo?: boolean;
}

export async function rotasUtilizadores(app: FastifyInstance) {
  // Esquema com nome, usado pelas respostas das leituras
  app.addSchema(esquemaUtilizador);

  const soAdmin = exigirCargo('Administrador');

  // GET /api/v1/utilizadores: lista as contas
  // GET /api/v1/utilizadores?por_aprovar=true: só as contas ativas à espera de aprovação
  app.get('/utilizadores', { schema: listarUtilizadores, preHandler: soAdmin }, async (request) => {
    const { por_aprovar } = request.query as { por_aprovar?: boolean };
    if (por_aprovar === true) {
      const resultado = await bd.query(
        'SELECT * FROM vw_utilizador WHERE data_aprovacao IS NULL AND ativo ORDER BY criado_em',
      );
      return resultado.rows;
    }
    const resultado = await bd.query('SELECT * FROM vw_utilizador ORDER BY nome');
    return resultado.rows;
  });

  // GET /api/v1/utilizadores/1: mostra uma conta
  app.get('/utilizadores/:id', { schema: obterUtilizador, preHandler: soAdmin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const resultado = await bd.query('SELECT * FROM vw_utilizador WHERE id = $1', [id]);
    if (resultado.rows.length === 0) {
      return enviarErro(reply, 404, 'O utilizador não existe.');
    }
    return resultado.rows[0];
  });

  // POST /api/v1/utilizadores: cria uma conta, já aprovada, com palavra-passe temporária
  app.post('/utilizadores', { schema: criarUtilizador, preHandler: soAdmin }, async (request, reply) => {
    const dados = request.body as DadosNovoUtilizador;
    const resultado = await escreverComo(
      request.user.id,
      `SELECT fn_utilizador_crud(
         p_operacao            => 'CREATE',
         p_id                  => NULL,
         p_cargo_id            => $1,
         p_cliente_id          => $2,
         p_nome                => $3,
         p_email               => $4,
         p_password_hash       => $5,
         p_password_temporaria => TRUE,
         p_aprovado_por        => $6
       ) AS id`,
      [
        dados.cargo_id,
        dados.cliente_id,
        dados.nome,
        dados.email,
        await bcrypt.hash(dados.password, configuracao.bcrypt.custo),
        request.user.id,
      ],
    );
    return enviarCriado(reply, 'utilizadores', resultado.rows[0].id);
  });

  // PATCH /api/v1/utilizadores/1: altera uma conta (só os campos que vierem)
  // Com "password", essa passa a ser a nova palavra-passe temporária.
  app.patch('/utilizadores/:id', { schema: alterarUtilizador, preHandler: soAdmin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const dados = request.body as DadosUtilizador;
    if (id === request.user.id && dados.ativo === false) {
      return enviarErro(reply, 400, 'Não pode desativar a sua própria conta.');
    }

    let passwordHash: string | null = null;
    if (dados.password !== undefined) {
      passwordHash = await bcrypt.hash(dados.password, configuracao.bcrypt.custo);
    }

    const resultado = await escreverComo(
      request.user.id,
      `SELECT fn_utilizador_crud(
         p_operacao            => 'UPDATE',
         p_id                  => $1,
         p_cargo_id            => $2,
         p_cliente_id          => $3,
         p_nome                => $4,
         p_email               => $5,
         p_password_hash       => $6,
         p_password_temporaria => $7,
         p_ativo               => $8
       ) AS id`,
      [
        id,
        dados.cargo_id,
        dados.cliente_id,
        dados.nome,
        dados.email,
        passwordHash,
        // nova palavra-passe = temporária; sem palavra-passe nova = fica como está (null)
        passwordHash !== null ? true : null,
        dados.ativo,
      ],
    );
    return resultado.rows[0];
  });

  // DELETE /api/v1/utilizadores/1: desativa a conta (também serve para recusar o registo de uma clínica)
  // Responde 204: correu bem e não há nada para devolver.
  app.delete('/utilizadores/:id', { schema: desativarUtilizador, preHandler: soAdmin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    if (id === request.user.id) {
      return enviarErro(reply, 400, 'Não pode desativar a sua própria conta.');
    }
    await escreverComo(request.user.id, "SELECT fn_utilizador_crud('DELETE', $1) AS id", [id]);
    return reply.code(204).send();
  });

  // GET /api/v1/colaboradores: as pessoas ativas do laboratório (para atribuir etapas)
  // Não é só do Administrador: os colaboradores também escolhem a quem fica a etapa seguinte.
  app.get(
    '/colaboradores',
    { schema: listarColaboradores, preHandler: exigirCargo('Administrador', 'Colaborador') },
    async () => {
      const resultado = await bd.query(
        'SELECT id, nome, cargo FROM vw_utilizador WHERE ativo AND cliente_id IS NULL ORDER BY nome',
      );
      return resultado.rows;
    },
  );

  // POST /api/v1/utilizadores/1/aprovar: aprova uma conta que está à espera
  app.post('/utilizadores/:id/aprovar', { schema: aprovarUtilizador, preHandler: soAdmin }, async (request) => {
    const { id } = request.params as { id: number };
    const resultado = await escreverComo(request.user.id, 'SELECT fn_aprovar_utilizador($1, $2) AS id', [id, request.user.id]);
    return resultado.rows[0];
  });
}
