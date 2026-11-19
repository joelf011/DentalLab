import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/autenticacao/pagina_login.dart';
import 'package:app_mobile/autenticacao/pagina_pendente.dart';
import 'package:app_mobile/autenticacao/pagina_registo.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/detalhe_encomenda/pagina_detalhe_encomenda.dart';
import 'package:app_mobile/cliente/ecra_cliente.dart';
import 'package:app_mobile/cliente/nova_encomenda/pagina_nova_encomenda.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/pagina_detalhe_trabalho.dart';
import 'package:app_mobile/colaborador/ecra_colaborador.dart';
import 'package:app_mobile/colaborador/trabalhos/pagina_prazos.dart';

// Rotas da app (package go_router).
// Os separadores da barra inferior NÃO são rotas: vivem dentro do
// EcraCliente e do EcraColaborador.

// Caminhos das rotas. Exemplo: context.go(Rotas.login)
class Rotas {
  // Autenticação
  static const login = '/';
  static const registo = '/registo';
  static const pendente = '/pendente';

  // Vista da clínica
  static const cliente = '/cliente';
  // Detalhe da encomenda. extra: Encomenda
  static const detalheEncomenda = '/cliente/encomenda';
  // Nova encomenda. Devolve true se a encomenda foi enviada.
  static const novaEncomenda = '/cliente/nova-encomenda';

  // Vista do colaborador e do administrador
  static const colaborador = '/colaborador';
  // Detalhe do trabalho. extra: Trabalho
  static const detalheTrabalho = '/colaborador/trabalho';
  // Gestão de prazos
  static const prazos = '/colaborador/prazos';
}

final rotas = GoRouter(
  initialLocation: Rotas.login,
  routes: [
    GoRoute(
      name: 'login',
      path: Rotas.login,
      builder: (context, state) => const PaginaLogin(),
    ),
    GoRoute(
      name: 'registo',
      path: Rotas.registo,
      builder: (context, state) => const PaginaRegisto(),
    ),
    GoRoute(
      name: 'pendente',
      path: Rotas.pendente,
      builder: (context, state) => const PaginaPendente(),
    ),
    GoRoute(
      name: 'cliente',
      path: Rotas.cliente,
      builder: (context, state) => _soComSessao(const EcraCliente()),
    ),
    GoRoute(
      name: 'detalheEncomenda',
      path: Rotas.detalheEncomenda,
      builder: (context, state) => _soComSessao(
        PaginaDetalheEncomenda(encomenda: state.extra! as Encomenda),
      ),
    ),
    GoRoute(
      name: 'novaEncomenda',
      path: Rotas.novaEncomenda,
      builder: (context, state) => _soComSessao(const PaginaNovaEncomenda()),
    ),
    GoRoute(
      name: 'colaborador',
      path: Rotas.colaborador,
      builder: (context, state) => _soComSessao(const EcraColaborador()),
    ),
    GoRoute(
      name: 'detalheTrabalho',
      path: Rotas.detalheTrabalho,
      builder: (context, state) => _soComSessao(
        PaginaDetalheTrabalho(trabalho: state.extra! as Trabalho),
      ),
    ),
    GoRoute(
      name: 'prazos',
      path: Rotas.prazos,
      builder: (context, state) => _soComSessao(const PaginaPrazos()),
    ),
  ],
);

// Sem sessão iniciada (por exemplo, depois de recarregar a página na web)
// mostra o aviso em vez do ecrã pedido.
Widget _soComSessao(Widget pagina) {
  if (Sessao.atual == null) return const _SessaoTerminada();
  return pagina;
}

class _SessaoTerminada extends StatefulWidget {
  const _SessaoTerminada();

  @override
  State<_SessaoTerminada> createState() => _SessaoTerminadaState();
}

class _SessaoTerminadaState extends State<_SessaoTerminada> {
  void _irParaLogin() {
    context.go(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('A sessão terminou. Inicie sessão novamente.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _irParaLogin,
                child: const Text('Ir para o início de sessão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
