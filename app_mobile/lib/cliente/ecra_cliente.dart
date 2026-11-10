import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/alertas/pagina_alertas.dart';
import 'package:app_mobile/cliente/conta/pagina_conta.dart';
import 'package:app_mobile/cliente/inicio/pagina_inicio_cliente.dart';
import 'package:app_mobile/cliente/pedidos/pagina_pedidos.dart';
import 'package:app_mobile/cliente/widget_barra_cliente.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_barra_superior.dart';

// Vista da clínica: barra superior + barra inferior com 5 separadores
// (Início, Pedidos, Novo, Alertas, Conta).
// O separador "Novo" não muda de separador: abre a Nova encomenda por cima.
class EcraCliente extends StatefulWidget {
  const EcraCliente({super.key});

  @override
  State<EcraCliente> createState() => _EcraClienteState();
}

class _EcraClienteState extends State<EcraCliente> {
  static const _separadorPedidos = 1;
  static const _separadorNovo = 2;
  static const _separadorAlertas = 3;

  int _indiceAtual = 0;

  void _selecionarDestino(int indice) {
    if (indice == _separadorNovo) {
      _abrirNovaEncomenda();
      return;
    }
    setState(() {
      _indiceAtual = indice;
    });
  }

  void _verPedidos() {
    _selecionarDestino(_separadorPedidos);
  }

  void _verAlertas() {
    _selecionarDestino(_separadorAlertas);
  }

  // Abre a Nova encomenda. Se foi enviada, mostra os Pedidos.
  Future<void> _abrirNovaEncomenda() async {
    final enviada = await context.push<bool>(Rotas.novaEncomenda);
    if (enviada == true && mounted) {
      setState(() {
        _indiceAtual = _separadorPedidos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecras = [
      PaginaInicioCliente(
        aoVerPedidos: _verPedidos,
        aoNovaEncomenda: _abrirNovaEncomenda,
      ),
      const PaginaPedidos(),
      const SizedBox.shrink(), // "Novo" abre por cima (_abrirNovaEncomenda)
      const PaginaAlertas(),
      const PaginaConta(),
    ];

    return Scaffold(
      appBar: BarraSuperior(
        nome: Sessao.atual!.clinica!.nome,
        acoes: [
          IconButton(
            tooltip: 'Alertas',
            onPressed: _verAlertas,
            icon: const Badge(
              label: Text('3'),
              backgroundColor: CoresApp.dourado,
              textColor: CoresApp.textoForte,
              child: Icon(Icons.notifications_none_outlined),
            ),
          ),
        ],
      ),
      body: ecras[_indiceAtual],
      bottomNavigationBar: BarraCliente(
        indiceAtual: _indiceAtual,
        aoSelecionar: _selecionarDestino,
      ),
    );
  }
}
