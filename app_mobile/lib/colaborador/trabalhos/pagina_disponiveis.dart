import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/trabalhos/widget_cartao_trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// Separador "Disponíveis": trabalhos cuja etapa seguinte ninguém assumiu
// (regra em Trabalho.estaDisponivel).
class PaginaDisponiveis extends StatefulWidget {
  const PaginaDisponiveis({super.key});

  @override
  State<PaginaDisponiveis> createState() => _PaginaDisponiveisState();
}

class _PaginaDisponiveisState extends State<PaginaDisponiveis> {
  final _servidor = const ServidorColaborador();
  late Future<List<Trabalho>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servidor.obterTrabalhos();
  }

  void _abrirTrabalho(Trabalho trabalho) {
    context.push(Rotas.detalheTrabalho, extra: trabalho);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Trabalho>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final disponiveis = snapshot.data!
              .where((trabalho) => trabalho.estaDisponivel)
              .toList();
          return _lista(disponiveis);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _lista(List<Trabalho> trabalhos) {
    if (trabalhos.isEmpty) return const EstadoVazio(mensagem: 'Sem trabalhos');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final trabalho in trabalhos)
          CartaoTrabalho(trabalho: trabalho, aoAbrir: _abrirTrabalho),
      ],
    );
  }
}
