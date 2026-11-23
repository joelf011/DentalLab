import Fastify from 'fastify';
import { rotasAlteracoesCliente } from './modulos/alteracoes-cliente/alteracoes-cliente.rotas.ts';
import { rotasAutenticacao } from './modulos/autenticacao/autenticacao.rotas.ts';
import { rotasCargos } from './modulos/cargos/cargos.rotas.ts';
import { rotasClientes } from './modulos/clientes/clientes.rotas.ts';
import { rotasSaude } from './modulos/saude/saude.rotas.ts';
import { rotasUtilizadores } from './modulos/utilizadores/utilizadores.rotas.ts';
import { registarCors } from './plugins/cors.ts';
import { registarJwt } from './plugins/jwt.ts';
import { registarTratamentoErros } from './plugins/tratamento-erros.ts';

// Constrói a API: liga os plugins e os módulos, mas não a põe a ouvir (isso é no servidor.ts).
// Assim, a API pode ser construída noutros sítios (por exemplo, num script de teste) sem abrir uma porta.
// mostrarPedidos: o terminal mostra cada pedido que chega (desliga-se nos scripts de teste).
export function construirApp(mostrarPedidos = true) {
  const app = Fastify({
    logger: mostrarPedidos ? { transport: { target: 'pino-pretty' } } : false,
  });

  // A API só recebe dados em JSON. O Fastify também aceita texto simples por omissão;
  // sem isto, um pedido em texto chegava à rota e dava um erro confuso, em vez de 415.
  app.removeContentTypeParser('text/plain');

  // Peças ligadas uma vez, para toda a API (pasta plugins/)
  registarTratamentoErros(app);
  registarCors(app);
  registarJwt(app);

  // Módulos: cada área tem a sua pasta em modulos/, com as suas rotas.
  // Todas ficam debaixo de /api/v1: o '/cargos' de cargos.rotas.ts passa a ser /api/v1/cargos.
  // Se um dia houver uma versão incompatível da API, regista-se a nova em /api/v2 sem mexer nesta.
  const versao1 = { prefix: '/api/v1' };
  app.register(rotasSaude, versao1);
  app.register(rotasAutenticacao, versao1);
  app.register(rotasCargos, versao1);
  app.register(rotasClientes, versao1);
  app.register(rotasAlteracoesCliente, versao1);
  app.register(rotasUtilizadores, versao1);

  return app;
}
