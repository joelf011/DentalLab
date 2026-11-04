import fastifyCors from '@fastify/cors';
import fastifyJwt from '@fastify/jwt';
import Fastify, { type FastifyError } from 'fastify';
import { config } from './config.ts';
import { bd } from './db.ts';
import { rotasAuth } from './rotas/auth.ts';
import { rotasCargos } from './rotas/cargos.ts';

// Cria o servidor. O logger mostra no terminal cada pedido que chega.
const app = Fastify({
  logger: { transport: { target: 'pino-pretty' } },
});

// Quando uma rota dá erro, vem parar aqui.
// Todas as respostas de erro têm o mesmo formato: { "erro": "mensagem" }
app.setErrorHandler((erro: FastifyError, request, reply) => {
  // Erro lançado por uma função da BD com RAISE EXCEPTION (ex.: "O cargo 9 não existe").
  // A mensagem já vem em português, por isso mostra-se tal como está.
  if (erro.code === 'P0001') {
    return reply.code(400).send({ erro: erro.message });
  }
  // Valor com formato errado para a BD (ex.: /api/cargos/abc, quando o id tem de ser um número).
  if (erro.code === '22P02') {
    return reply.code(400).send({ erro: 'Há um valor com formato inválido.' });
  }
  // Erros do próprio Fastify com código conhecido (ex.: JSON mal escrito no corpo do pedido).
  if (erro.statusCode !== undefined && erro.statusCode < 500) {
    return reply.code(erro.statusCode).send({ erro: erro.message });
  }
  // Qualquer outro erro fica registado no terminal; quem fez o pedido recebe uma mensagem genérica.
  request.log.error(erro);
  return reply.code(500).send({ erro: 'Ocorreu um erro inesperado.' });
});

// Pedido para uma rota que não existe.
app.setNotFoundHandler((_request, reply) => {
  return reply.code(404).send({ erro: 'Esta rota não existe.' });
});

// GET /api/health: confirma que a API está a funcionar e que consegue falar com a BD.
app.get('/api/health', async (request, reply) => {
  try {
    await bd.query('SELECT 1');
    return { api: 'ok', bd: 'ok' };
  } catch (erro) {
    request.log.error(erro);
    return reply.code(503).send({ api: 'ok', bd: 'sem ligação' });
  }
});

// CORS: autoriza os sites React (CORS_ORIGENS no .env) a usar a API a partir do navegador.
// Sem isto, o navegador bloqueia os pedidos do React (localhost:5173) para a API (localhost:3000).
// A app Flutter não é um navegador, por isso não precisa disto.
app.register(fastifyCors, {
  origin: config.corsOrigens,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
});

// Login com tokens (JWT). A partir daqui passam a existir app.jwt.sign() (cria um token)
// e request.jwtVerify() (verifica o token de um pedido; usado em autenticacao.ts).
app.register(fastifyJwt, {
  secret: config.jwt.segredo,
  sign: { expiresIn: config.jwt.validade },
});

// Cada grupo de rotas está num ficheiro da pasta rotas/.
app.register(rotasAuth);
app.register(rotasCargos);

// Arranca o servidor.
// host '0.0.0.0' = aceita pedidos de qualquer rede do PC, e não só do próprio PC (localhost).
// É o que permite ao emulador Android e aos telemóveis na mesma rede Wi-Fi chegarem à API.
// Ao arrancar, o terminal mostra os endereços: o que não é 127.0.0.1 é o que se usa no telemóvel.
await app.listen({ port: config.porta, host: '0.0.0.0' });
