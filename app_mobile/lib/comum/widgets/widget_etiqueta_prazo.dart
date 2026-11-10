import 'package:flutter/material.dart';

import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

// Etiqueta com o prazo: "3d", "2d atraso" ou "Concluído", e a data por baixo.
// Exemplo: EtiquetaPrazo(prazo: trabalho.prazo, concluido: trabalho.estado == 'concluido')
class EtiquetaPrazo extends StatelessWidget {
  const EtiquetaPrazo({super.key, required this.prazo, this.concluido = false});

  final DateTime prazo;
  final bool concluido;

  @override
  Widget build(BuildContext context) {
    final dias = diasAte(prazo);
    final String texto;
    if (concluido) {
      texto = 'Concluído';
    } else if (dias < 0) {
      texto = '${-dias}d atraso';
    } else {
      texto = '${dias}d';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CoresApp.fundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(texto, style: const TextStyle(fontSize: 12)),
          Text(dataCurta(prazo), style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
