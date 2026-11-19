import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/trabalhos/widget_cartao_trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// "Gestão de Prazos": todos os trabalhos urgentes (Trabalho.eUrgente),
// do prazo mais próximo para o mais distante.
// Rota: Rotas.prazos (abre por cima, com seta para voltar).
class PaginaPrazos extends StatefulWidget {
  const PaginaPrazos({super.key});

  @override
  State<PaginaPrazos> createState() => _PaginaPrazosState();
}

class _PaginaPrazosState extends State<PaginaPrazos> {
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

  // Os urgentes têm sempre prazo (Trabalho.eUrgente).
  int _compararPrazo(Trabalho primeiro, Trabalho segundo) {
    return primeiro.prazoEntrega!.compareTo(segundo.prazoEntrega!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Prazos')),
      body: SafeArea(
        child: FutureBuilder<List<Trabalho>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final urgentes = snapshot.data!
                  .where((trabalho) => trabalho.eUrgente)
                  .toList();
              urgentes.sort(_compararPrazo);
              return _lista(urgentes);
            } else if (snapshot.hasError) {
              return const Center(child: Text('Ocorreu um erro'));
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _lista(List<Trabalho> trabalhos) {
    if (trabalhos.isEmpty) {
      return const EstadoVazio(mensagem: 'Sem trabalhos urgentes.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trabalhos.length,
      itemBuilder: (context, indice) {
        final trabalho = trabalhos[indice];
        return CartaoTrabalho(
          key: ValueKey(trabalho.id),
          trabalho: trabalho,
          aoAbrir: _abrirTrabalho,
        );
      },
    );
  }
}
