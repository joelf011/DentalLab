import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/cliente/pedidos/widget_cartao_encomenda.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// Separador "Pedidos" da clínica: todas as encomendas da clínica.
class PaginaPedidos extends StatefulWidget {
  const PaginaPedidos({super.key});

  @override
  State<PaginaPedidos> createState() => _PaginaPedidosState();
}

class _PaginaPedidosState extends State<PaginaPedidos> {
  final _servidor = const ServidorCliente();
  late Future<List<Encomenda>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servidor.obterEncomendas(Sessao.atual!.clinica!.id);
  }

  void _abrirEncomenda(Encomenda encomenda) {
    context.push(Rotas.detalheEncomenda, extra: encomenda);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Encomenda>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _lista(snapshot.data!);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _lista(List<Encomenda> encomendas) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Encomendas',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            color: CoresApp.textoForte,
          ),
        ),
        const SizedBox(height: 16),
        if (encomendas.isEmpty)
          const EstadoVazio(mensagem: 'Ainda não há encomendas.')
        else
          for (final encomenda in encomendas)
            CartaoEncomenda(encomenda: encomenda, aoAbrir: _abrirEncomenda),
      ],
    );
  }
}
