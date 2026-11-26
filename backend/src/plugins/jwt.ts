import fastifyCookie from '@fastify/cookie';
import fastifyJwt from '@fastify/jwt';
import type { FastifyInstance } from 'fastify';
import { configuracao } from '../configuracao.ts';

// Nome do cookie onde o site guarda a sessão (ver modulos/autenticacao)
export const COOKIE_SESSAO = 'sessao';

// Login com tokens (JWT). A partir daqui passam a existir app.jwt.sign() (cria um token)
// e request.jwtVerify() (verifica o token de um pedido; usado em comum/acesso.ts).
//
// O token pode chegar de duas formas, e as duas servem nas mesmas rotas (como em AI3):
// - app (Flutter): no cabeçalho "Authorization: Bearer <token>";
// - site (React): no cookie "sessao", que o navegador guarda e envia sozinho.
// Se vierem os dois, conta o cabeçalho.
export function registarJwt(app: FastifyInstance) {
  // Lê os cookies dos pedidos (request.cookies) e permite enviá-los nas respostas (reply.setCookie)
  app.register(fastifyCookie);

  app.register(fastifyJwt, {
    secret: configuracao.jwt.segredo,
    cookie: { cookieName: COOKIE_SESSAO, signed: false },
    // Só se usa o algoritmo HS256: um token com outro algoritmo (ex.: "none", sem assinatura) é recusado.
    // A validade (expiresIn) é em segundos.
    sign: { algorithm: 'HS256', expiresIn: configuracao.jwt.validade },
    verify: { algorithms: ['HS256'] },
  });
}
