import type { FastifyInstance } from 'fastify';
import { enviarEmail } from '../../comum/email.ts';
import { enviarErro } from '../../comum/erros.ts';
import { configuracao } from '../../configuracao.ts';
import { enviarContacto } from './contactos.esquemas.ts';

// Rotas dos contactos: o formulário de contacto da página pública do site.
// A mensagem não fica na BD: vai por email para o laboratório (EMAIL_LABORATORIO no .env).

// O que o formulário envia
interface DadosContacto {
  clinica: string;
  nome: string;
  email: string;
  telefone?: string;
  assunto: string;
  mensagem: string;
}

export async function rotasContactos(app: FastifyInstance) {
  // POST /api/v1/contactos: envia a mensagem do formulário ao laboratório
  app.post('/contactos', { schema: enviarContacto }, async (request, reply) => {
    const dados = request.body as DadosContacto;
    try {
      await enviarEmail({
        para: configuracao.email.laboratorio,
        // ao carregar em "Responder", a resposta vai para quem escreveu
        responderA: dados.email,
        assunto: `Contacto do site: ${dados.assunto}`,
        texto:
          `Clínica: ${dados.clinica}\n` +
          `Nome: ${dados.nome}\n` +
          `Email: ${dados.email}\n` +
          `Telefone: ${dados.telefone || '(não indicou)'}\n` +
          `Assunto: ${dados.assunto}\n\n` +
          `${dados.mensagem}\n`,
      });
    } catch (erro) {
      // Aqui espera-se pelo envio: se o servidor de email falhar, quem escreveu tem de saber.
      request.log.error(erro);
      return enviarErro(reply, 503, 'Não foi possível enviar a mensagem. Tente mais tarde ou contacte-nos por telefone.');
    }
    return reply.code(204).send();
  });
}
