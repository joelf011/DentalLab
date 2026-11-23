import fastifyJwt from '@fastify/jwt';
import type { FastifyInstance } from 'fastify';
import { configuracao } from '../configuracao.ts';

// Login com tokens (JWT). A partir daqui passam a existir app.jwt.sign() (cria um token)
// e request.jwtVerify() (verifica o token de um pedido; usado em comum/acesso.ts).
export function registarJwt(app: FastifyInstance) {
  app.register(fastifyJwt, {
    secret: configuracao.jwt.segredo,
    sign: { expiresIn: configuracao.jwt.validade },
  });
}
