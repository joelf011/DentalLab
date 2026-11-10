import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// Aba "Histórico": acontecimentos numerados, do primeiro ao mais recente.
class AbaHistorico extends StatelessWidget {
  const AbaHistorico({super.key, required this.encomenda});

  final Encomenda encomenda;

  @override
  Widget build(BuildContext context) {
    final eventos = encomenda.eventos;
    if (eventos.isEmpty) {
      return const EstadoVazio(
        mensagem: 'Ainda não existem eventos nesta encomenda.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: eventos.length,
      itemBuilder: (context, indice) {
        final evento = eventos[indice];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: CoresApp.douradoClaro,
              foregroundColor: CoresApp.douradoEscuro,
              child: Text('${indice + 1}'),
            ),
            title: Text(evento.descricao),
            subtitle: Text('${evento.autor} · ${evento.data}'),
          ),
        );
      },
    );
  }
}
