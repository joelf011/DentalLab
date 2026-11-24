import bcrypt from 'bcryptjs';
import type { FastifyInstance } from 'fastify';
import { createHash } from 'node:crypto';
import { type DadosRecuperacao, enviarSemSessao, exigirLogin } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarEmail } from '../../comum/email.ts';
import { enviarErro } from '../../comum/erros.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import { configuracao } from '../../configuracao.ts';
import { concluirRecuperacao, mudarPalavraPasse, pedirRecuperacao, registarClinica } from './conta.esquemas.ts';

// Rotas da conta: uma clínica regista-se, quem está ligado muda a palavra-passe,
// e quem se esqueceu dela recupera-a por email.
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

// Escolher a palavra-passe nova com o código do link de recuperação
interface DadosConcluirRecuperacao {
  codigo: string;
  password_nova: string;
}

const LINK_INVALIDO = 'O link de recuperação não é válido ou já expirou. Peça um novo.';

// Recuperação da palavra-passe, sem tabela nova na BD:
// o link do email leva um token assinado pela API com um segredo próprio (configuracao.jwt.segredoRecuperacao),
// válido durante 1 hora. Dentro dele vai o id da conta e uma "impressão" do hash atual da palavra-passe.
// Quando a palavra-passe muda, a impressão deixa de bater certo e o link deixa de servir: só se usa uma vez.
// (Não vai o próprio hash, porque o conteúdo de um token lê-se sem o segredo.)
function impressaoDe(passwordHash: string) {
  return createHash('sha256').update(passwordHash).digest('hex').slice(0, 16);
}

// Quando foi enviado o último email de recuperação de cada conta (em memória; esquece-se se a API reiniciar).
// No máximo um email a cada 2 minutos, para ninguém encher a caixa de correio de outra pessoa com pedidos.
const ultimoEnvio = new Map<number, number>();
const INTERVALO_ENVIOS = 2 * 60 * 1000;

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

  // Cria o link de recuperação de uma conta e envia-o por email
  async function enviarLinkRecuperacao(conta: { id: number; nome: string; email: string; password_hash: string }) {
    const dados: DadosRecuperacao = { id: conta.id, impressao: impressaoDe(conta.password_hash) };
    const codigo = app.jwt.sign(dados, {
      key: configuracao.jwt.segredoRecuperacao,
      expiresIn: configuracao.jwt.validadeRecuperacao,
    });
    const link = `${configuracao.urlSite}/#/recuperar?codigo=${codigo}`;
    await enviarEmail({
      para: conta.email,
      assunto: 'Recuperar a palavra-passe do DentalLab',
      texto:
        `Olá, ${conta.nome}.\n\n` +
        'Recebemos um pedido para recuperar a palavra-passe da sua conta no DentalLab.\n' +
        'Para escolher uma palavra-passe nova, abra este link (válido durante 1 hora):\n\n' +
        `${link}\n\n` +
        'Se não foi você que pediu, ignore este email: a sua palavra-passe continua igual.\n',
    });
  }

  // POST /api/v1/recuperacoes com { "email": "..." }: pede o link para escolher uma palavra-passe nova
  // Responde sempre 204, haja ou não conta com esse email, e no mesmo tempo: o link é criado e enviado
  // só depois da resposta (setImmediate), sem esperar pelo servidor de email.
  // Assim, nem a resposta nem o tempo que ela demora revelam que emails têm conta.
  app.post('/recuperacoes', { schema: pedirRecuperacao }, async (request, reply) => {
    const { email } = request.body as { email: string };
    const resultado = await bd.query('SELECT * FROM fn_utilizador_login($1)', [email]);
    const conta = resultado.rows[0];

    // Só as contas que podem entrar (ativas e aprovadas), e no máximo um email a cada 2 minutos
    const agora = Date.now();
    const recente = conta && agora - (ultimoEnvio.get(conta.id) ?? 0) < INTERVALO_ENVIOS;
    if (conta && conta.ativo && conta.aprovado && !recente) {
      ultimoEnvio.set(conta.id, agora);
      // Se o envio falhar, fica registado no terminal (quem pediu já recebeu a resposta)
      setImmediate(() => enviarLinkRecuperacao(conta).catch((erro) => request.log.error(erro)));
    }
    return reply.code(204).send();
  });

  // POST /api/v1/recuperacoes/concluir com { "codigo": "...", "password_nova": "..." }
  // O código vem no link do email. Se servir, a palavra-passe muda e deixa de ser temporária.
  app.post('/recuperacoes/concluir', { schema: concluirRecuperacao }, async (request, reply) => {
    const dados = request.body as DadosConcluirRecuperacao;

    // 1. O código tem de ter sido assinado com o segredo da recuperação e não pode ter expirado
    let recuperacao: DadosRecuperacao;
    try {
      recuperacao = app.jwt.verify<DadosRecuperacao>(dados.codigo, { key: configuracao.jwt.segredoRecuperacao });
    } catch {
      return enviarErro(reply, 400, LINK_INVALIDO);
    }

    // 2. A conta tem de continuar ativa, e a palavra-passe tem de ser a mesma de quando o link foi pedido
    const conta = await bd.query('SELECT email FROM vw_utilizador WHERE id = $1 AND ativo', [recuperacao.id]);
    if (conta.rows.length === 0) {
      return enviarErro(reply, 400, LINK_INVALIDO);
    }
    const credenciais = await bd.query('SELECT password_hash FROM fn_utilizador_login($1)', [conta.rows[0].email]);
    if (impressaoDe(credenciais.rows[0].password_hash) !== recuperacao.impressao) {
      return enviarErro(reply, 400, LINK_INVALIDO);
    }

    // 3. Muda a palavra-passe. Fica na auditoria como feito pela própria conta (escreverComo com o id dela).
    const novoHash = await bcrypt.hash(dados.password_nova, configuracao.bcrypt.custo);
    await escreverComo(
      recuperacao.id,
      `SELECT fn_utilizador_crud(
         p_operacao            => 'UPDATE',
         p_id                  => $1,
         p_password_hash       => $2,
         p_password_temporaria => false
       ) AS id`,
      [recuperacao.id, novoHash],
    );
    return reply.code(204).send();
  });
}
