import bcrypt from 'bcryptjs';
import type { FastifyInstance } from 'fastify';
import { enviarSemSessao, exigirLogin } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import { configuracao } from '../../configuracao.ts';
import { mudarPalavraPasse, registarClinica } from './conta.esquemas.ts';

// Rotas da conta: uma clínica regista-se e quem está ligado muda a palavra-passe.
// A BD nunca recebe a palavra-passe, só o hash (bcrypt). O password_hash só se lê com fn_utilizador_login.
// As regras dos dados (obrigatórios, tamanhos, NIF) estão em conta.esquemas.ts.

// Registo de uma clínica
interface DadosRegisto {
  nome: string;
  nif: string;
  morada_faturacao?: string;
  telefone?: string;
  email: string; // é o email de contacto da clínica e o email de login
  password: string;
}

// Mudar a palavra-passe
interface DadosPalavraPasse {
  password_atual: string;
  password_nova: string;
}

export async function rotasConta(app: FastifyInstance) {
  // POST /api/v1/registos: uma clínica regista-se sozinha (rota pública, sem login)
  // Cria a clínica e a conta de acesso, que fica à espera de aprovação do Administrador.
  // Até ser aprovada, o login responde 403 "A sua conta ainda não foi aprovada pelo laboratório."
  app.post('/registos', { schema: registarClinica }, async (request, reply) => {
    const dados = request.body as DadosRegisto;
    // A função na BD confirma o resto (NIF ou email repetidos...).
    const resultado = await escreverComo(
      null,
      `SELECT fn_registar_clinica(
         p_nome             => $1,
         p_nif              => $2,
         p_morada_faturacao => $3,
         p_telefone         => $4,
         p_email            => $5,
         p_password_hash    => $6
       ) AS id`,
      [
        dados.nome,
        dados.nif,
        dados.morada_faturacao,
        dados.telefone,
        dados.email,
        await bcrypt.hash(dados.password, configuracao.bcrypt.custo),
      ],
    );
    return enviarCriado(reply, 'clientes', resultado.rows[0].id);
  });

  // PUT /api/v1/conta/palavra-passe com { "password_atual": "...", "password_nova": "..." }
  // Muda a palavra-passe de quem está ligado e deixa de ser temporária.
  app.put('/conta/palavra-passe', { schema: mudarPalavraPasse, preHandler: exigirLogin }, async (request, reply) => {
    const dados = request.body as DadosPalavraPasse;
    // Uma regra que compara dois campos não cabe no esquema, por isso fica aqui.
    if (dados.password_nova === dados.password_atual) {
      return enviarErro(reply, 400, 'A nova palavra-passe tem de ser diferente da atual.');
    }

    // Vai buscar o hash atual: primeiro o email (pelo id da sessão), depois as credenciais.
    const conta = await bd.query('SELECT email FROM vw_utilizador WHERE id = $1 AND ativo', [request.user.id]);
    if (conta.rows.length === 0) {
      return enviarSemSessao(reply, 'Esta conta já não está ativa.', true);
    }
    const credenciais = await bd.query('SELECT password_hash FROM fn_utilizador_login($1)', [conta.rows[0].email]);

    // 400 e não 401: o frontend trata o 401 como "sessão terminada", e aqui a sessão está boa.
    if (!(await bcrypt.compare(dados.password_atual, credenciais.rows[0].password_hash))) {
      return enviarErro(reply, 400, 'A palavra-passe atual está errada.');
    }

    const novoHash = await bcrypt.hash(dados.password_nova, configuracao.bcrypt.custo);
    const resultado = await escreverComo(
      request.user.id,
      `SELECT fn_utilizador_crud(
         p_operacao            => 'UPDATE',
         p_id                  => $1,
         p_password_hash       => $2,
         p_password_temporaria => false
       ) AS id`,
      [request.user.id, novoHash],
    );
    return resultado.rows[0];
  });
}
