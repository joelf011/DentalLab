import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

// Aba "Histórico": momentos da encomenda numerados, do primeiro ao mais recente.
class AbaHistorico extends StatelessWidget {
  const AbaHistorico({super.key, required this.encomenda});

  final Encomenda encomenda;

  @override
  Widget build(BuildContext context) {
    final eventos = encomenda.historico;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Do primeiro ao mais recente · siga a numeração.',
            style: TextStyle(fontSize: 12, color: CoresApp.textoSuave),
          ),
        ),
        for (final (indice, evento) in eventos.indexed)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: CoresApp.douradoClaro,
                foregroundColor: CoresApp.douradoEscuro,
                child: Text('${indice + 1}'),
              ),
              title: Text(evento.descricao),
              subtitle: Text(dataHora(evento.data)),
            ),
          ),
      ],
    );
  }
}
