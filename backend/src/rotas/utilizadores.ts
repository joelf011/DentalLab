import bcrypt from 'bcryptjs';
import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../autenticacao.ts';
import { bd } from '../db.ts';

// Rotas das contas de acesso (utilizadores). Todas são do Administrador.
// Ler: vista vw_utilizador (não mostra o password_hash).
// Criar, alterar e desativar: fn_utilizador_crud. Aprovar: fn_aprovar_utilizador.
// As contas criadas pelo Administrador ficam logo aprovadas, com uma palavra-passe temporária
// que a pessoa tem de mudar no primeiro login (PUT /api/auth/password).

// O que o frontend envia no corpo do pedido (POST e PUT)
interface DadosUtilizador {
  nome?: string;
  email?: string;
  cargo_id?: number;
  cliente_id?: number; // só para o cargo Cliente: a clínica a que a conta pertence
  password?: string; // palavra-passe temporária
  ativo?: boolean;
}

// A palavra-passe chega em texto e só o hash vai para a BD, por isso esta regra fica aqui.
function passwordValida(password: string): boolean {
  return password.length >= 8;
}

export async function rotasUtilizadores(app: FastifyInstance) {
  const soAdmin = { preHandler: exigirCargo('Administrador') };

  // GET /api/utilizadores: lista as contas
  // GET /api/utilizadores?por_aprovar=true: só as contas ativas à espera de aprovação
  app.get('/api/utilizadores', soAdmin, async (request) => {
    const { por_aprovar } = request.query as { por_aprovar?: string };
    if (por_aprovar === 'true') {
      const resultado = await bd.query(
        'SELECT * FROM vw_utilizador WHERE data_aprovacao IS NULL AND ativo ORDER BY criado_em',
      );
      return resultado.rows;
    }
    const resultado = await bd.query('SELECT * FROM vw_utilizador ORDER BY nome');
    return resultado.rows;
  });

  // GET /api/utilizadores/1: mostra uma conta
  app.get('/api/utilizadores/:id', soAdmin, async (request, reply) => {
    const { id } = request.params as { id: string };
    const resultado = await bd.query('SELECT * FROM vw_utilizador WHERE id = $1', [id]);
    if (resultado.rows.length === 0) {
      return reply.code(404).send({ erro: 'O utilizador não existe.' });
    }
    return resultado.rows[0];
  });

  // POST /api/utilizadores: cria uma conta, já aprovada, com palavra-passe temporária
  app.post('/api/utilizadores', soAdmin, async (request, reply) => {
    const dados = request.body as DadosUtilizador | undefined;
    if (!dados?.password || !passwordValida(dados.password)) {
      return reply.code(400).send({ erro: 'A palavra-passe tem de ter pelo menos 8 caracteres.' });
    }
    const resultado = await bd.query(
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
      [dados.cargo_id, dados.cliente_id, dados.nome, dados.email, await bcrypt.hash(dados.password, 12), request.user.id],
    );
    return reply.code(201).send(resultado.rows[0]);
  });

  // PUT /api/utilizadores/1: altera uma conta (só os campos que vierem)
  // Com "password", essa passa a ser a nova palavra-passe temporária.
  app.put('/api/utilizadores/:id', soAdmin, async (request, reply) => {
    const { id } = request.params as { id: string };
    const dados = request.body as DadosUtilizador | undefined;
    if (Number(id) === request.user.id && dados?.ativo === false) {
      return reply.code(400).send({ erro: 'Não pode desativar a sua própria conta.' });
    }

    let passwordHash: string | null = null;
    if (dados?.password !== undefined) {
      if (!passwordValida(dados.password)) {
        return reply.code(400).send({ erro: 'A palavra-passe tem de ter pelo menos 8 caracteres.' });
      }
      passwordHash = await bcrypt.hash(dados.password, 12);
    }

    const resultado = await bd.query(
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
        dados?.cargo_id,
        dados?.cliente_id,
        dados?.nome,
        dados?.email,
        passwordHash,
        // nova palavra-passe = temporária; sem palavra-passe nova = fica como está (null)
        passwordHash !== null ? true : null,
        dados?.ativo,
      ],
    );
    return resultado.rows[0];
  });

  // DELETE /api/utilizadores/1: desativa a conta (também serve para recusar o registo de uma clínica)
  app.delete('/api/utilizadores/:id', soAdmin, async (request, reply) => {
    const { id } = request.params as { id: string };
    if (Number(id) === request.user.id) {
      return reply.code(400).send({ erro: 'Não pode desativar a sua própria conta.' });
    }
    const resultado = await bd.query("SELECT fn_utilizador_crud('DELETE', $1) AS id", [id]);
    return resultado.rows[0];
  });

  // POST /api/utilizadores/1/aprovar: aprova uma conta que está à espera
  app.post('/api/utilizadores/:id/aprovar', soAdmin, async (request) => {
    const { id } = request.params as { id: string };
    const resultado = await bd.query('SELECT fn_aprovar_utilizador($1, $2) AS id', [id, request.user.id]);
    return resultado.rows[0];
  });
}
