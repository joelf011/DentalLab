import fastifySwagger from '@fastify/swagger';
import fastifySwaggerUi from '@fastify/swagger-ui';
import type { FastifyInstance } from 'fastify';
import { PREFIXO_API } from '../comum/respostas.ts';

// Documentação da API (OpenAPI), gerada a partir dos esquemas das rotas (ficheiros <area>.esquemas.ts):
// - página para ler e experimentar os pedidos: http://localhost:3000/api/v1/docs
// - o contrato em JSON (OpenAPI 3):            http://localhost:3000/api/v1/docs/json
// Como é gerada a partir das rotas, diz sempre o que a API faz de verdade.
// Tem de ser registada antes dos módulos, para os ver a todos.
export function registarDocumentacao(app: FastifyInstance) {
  app.register(fastifySwagger, {
    openapi: {
      openapi: '3.0.3',
      info: {
        title: 'API DentalLab',
        version: '1.0.0',
        description: [
          'API do laboratório DentalLab, usada pelo site, pelo backoffice (React) e pela app (Flutter).',
          '',
          '- Os dados vão e vêm em JSON. Os nomes dos campos são os das colunas da base de dados.',
          '- Quase todas as rotas precisam de sessão: a app envia o token no cabeçalho `Authorization: Bearer <token>`',
          '  (obtido em `POST /tokens`); o site usa o cookie `sessao` (criado em `POST /sessao`).',
          '  Para experimentar aqui: `POST /tokens`, copiar o token e colá-lo no botão **Authorize**.',
          '- Os erros têm sempre o formato `Erro`: `{ codigo, mensagem, detalhes }`.',
          '- O cabeçalho `Cache-Control` diz se a resposta se pode guardar: `private, no-cache` nas leituras',
          '  com login e `no-store` nas escritas, no login e nos erros.',
        ].join('\n'),
      },
      tags: [
        { name: 'Saúde', description: 'Estado da API e da ligação à base de dados.' },
        { name: 'Autenticação', description: 'Entrar e sair: token da app e sessão do site (cookie).' },
        { name: 'Conta', description: 'Registo de clínicas, palavra-passe e recuperação por email.' },
        { name: 'Cargos', description: 'Administrador, Colaborador e Cliente.' },
        { name: 'Clientes', description: 'As clínicas.' },
        { name: 'Alterações de cliente', description: 'Pedidos das clínicas para mudar os seus dados.' },
        { name: 'Utilizadores', description: 'Contas de acesso.' },
      ],
      components: {
        securitySchemes: {
          tokenJWT: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
            description: [
              'Token devolvido por `POST /tokens` (app), válido durante 7 dias. Tem estes dados:',
              '',
              '| Campo | Significado |',
              '| --- | --- |',
              '| `id` | Id do utilizador |',
              '| `nome` | Nome do utilizador |',
              '| `cargo` | `Administrador`, `Colaborador` ou `Cliente` |',
              '| `cliente_id` | A clínica da conta (só no cargo Cliente; nos outros é `null`) |',
              '| `iat` | Quando foi emitido (segundos desde 1970) |',
              '| `exp` | Quando expira (segundos desde 1970) |',
            ].join('\n'),
          },
          // O mesmo token, guardado pelo navegador no cookie "sessao" (é o que o site usa)
          cookieSessao: {
            type: 'apiKey',
            in: 'cookie',
            name: 'sessao',
            description: [
              'O mesmo token, no cookie `sessao`, que o navegador envia sozinho. Criado por `POST /sessao` e apagado',
              'por `DELETE /sessao`.',
              '',
              '| Atributo | Significado |',
              '| --- | --- |',
              '| `Max-Age=604800` | Dura 7 dias, tal como o token |',
              '| `Path=/api/v1` | Só é enviado para os endereços da API |',
              '| `HttpOnly` | O JavaScript da página não o consegue ler |',
              '| `SameSite=Strict` | Só é enviado em pedidos feitos a partir do próprio site |',
            ].join('\n'),
          },
        },
      },
      // Por omissão, todas as rotas precisam de sessão: o token OU o cookie (são alternativas).
      // As rotas públicas indicam security: [].
      security: [{ tokenJWT: [] }, { cookieSessao: [] }],
    },
    // Os esquemas com nome (ex.: $id: 'Cargo') aparecem na documentação com esse nome.
    refResolver: {
      buildLocalReference: (esquema, _base, _fragmento, i) => (typeof esquema.$id === 'string' ? esquema.$id : `esquema-${i}`),
    },
  });

  app.register(fastifySwaggerUi, { routePrefix: `${PREFIXO_API}/docs` });
}
