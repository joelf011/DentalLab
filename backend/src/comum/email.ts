import nodemailer from 'nodemailer';
import { configuracao } from '../configuracao.ts';

// Envio de emails por SMTP (recuperação da palavra-passe e formulário de contacto do site).
// O servidor SMTP fica no .env (ex.: Gmail, com uma "palavra-passe de aplicação").
// Sem SMTP_HOST no .env, nada é enviado: o email aparece no terminal da API, para se poder testar sem conta de email.

export interface Email {
  para: string;
  assunto: string;
  texto: string;
  responderA?: string; // quando se carrega em "Responder", a resposta vai para aqui
}

const { smtp } = configuracao.email;

// A ligação ao servidor SMTP (null se não houver servidor no .env)
const transporte = smtp.host
  ? nodemailer.createTransport({
      host: smtp.host,
      port: smtp.port,
      // Porta 465: ligação cifrada desde o início. Porta 587: começa normal e passa a cifrada (STARTTLS).
      secure: smtp.port === 465,
      auth: smtp.utilizador ? { user: smtp.utilizador, pass: smtp.palavraPasse } : undefined,
    })
  : null;

// Envia um email. Se o servidor SMTP falhar, lança um erro (quem chama decide o que fazer).
export async function enviarEmail(email: Email) {
  if (!transporte) {
    console.log(
      `\n--- Email (não enviado: não há SMTP_HOST no .env) ---\n` +
        `Para: ${email.para}\nAssunto: ${email.assunto}\n` +
        (email.responderA ? `Responder a: ${email.responderA}\n` : '') +
        `\n${email.texto}\n----------------------------------------------------\n`,
    );
    return;
  }
  await transporte.sendMail({
    from: configuracao.email.remetente,
    to: email.para,
    subject: email.assunto,
    text: email.texto,
    replyTo: email.responderA,
  });
}
