import { respostaSemConteudo, respostasErro } from '../../comum/esquemas.ts';

// Esquemas das rotas dos contactos (ver comum/esquemas.ts)

// Os assuntos do formulário de contacto do site
const assuntos = ['Informações sobre trabalhos', 'Pedido de orçamento', 'Outro assunto'];

// POST /api/v1/contactos
export const enviarContacto = {
  tags: ['Contactos'],
  operationId: 'enviarContacto',
  summary: 'Enviar uma mensagem ao laboratório',
  description:
    'O formulário de contacto da página pública do site. A mensagem vai por email para o laboratório; ' +
    'ao responder, a resposta vai para o email de quem escreveu. Não fica guardada na base de dados.',
  security: [], // pública: quem escreve ainda não é cliente
  body: {
    type: 'object',
    properties: {
      clinica: { type: 'string', minLength: 1, maxLength: 150 },
      nome: { type: 'string', minLength: 1, maxLength: 150 },
      email: { type: 'string', format: 'email', maxLength: 254 },
      telefone: { type: 'string', maxLength: 20 },
      assunto: { type: 'string', enum: assuntos },
      mensagem: { type: 'string', minLength: 1, maxLength: 5000 },
    },
    required: ['clinica', 'nome', 'email', 'assunto', 'mensagem'],
    additionalProperties: false,
  },
  response: {
    204: respostaSemConteudo,
    ...respostasErro(400, 503),
  },
};
