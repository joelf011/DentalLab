import 'package:flutter/material.dart';

import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_prazo.dart';

// Cartão de um trabalho (Início, Disponíveis, Os Meus, Prazos).
// Ao tocar chama aoAbrir(trabalho).
class CartaoTrabalho extends StatelessWidget {
  const CartaoTrabalho({
    super.key,
    required this.trabalho,
    required this.aoAbrir,
  });

  final Trabalho trabalho;
  final ValueChanged<Trabalho> aoAbrir;

  void _abrir() {
    aoAbrir(trabalho);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: _abrir,
        title: Text(trabalho.descricao),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${trabalho.referencia} · ${trabalho.clinica}'),
              EtiquetaEstado(estado: trabalho.estado),
            ],
          ),
        ),
        trailing: EtiquetaPrazo(
          prazo: trabalho.prazo,
          concluido: trabalho.estado == 'concluido',
        ),
      ),
    );
  }
}
