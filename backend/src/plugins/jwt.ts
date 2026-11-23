import fastifyJwt from '@fastify/jwt';
import type { FastifyInstance } from 'fastify';
import { configuracao } from '../configuracao.ts';

// Login com tokens (JWT). A partir daqui passam a existir app.jwt.sign() (cria um token)
// e request.jwtVerify() (verifica o token de um pedido; usado em comum/acesso.ts).
export function registarJwt(app: FastifyInstance) {
  app.register(fastifyJwt, {
    secret: configuracao.jwt.segredo,
    // Só se usa o algoritmo HS256: um token com outro algoritmo (ex.: "none", sem assinatura) é recusado.
    sign: { algorithm: 'HS256', expiresIn: configuracao.jwt.validade },
    verify: { algorithms: ['HS256'] },
  });
}
