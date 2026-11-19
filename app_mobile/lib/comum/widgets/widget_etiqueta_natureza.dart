import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Etiqueta com a natureza do trabalho: "Físico" ou "Digital".
// Exemplo: EtiquetaNatureza(natureza: encomenda.natureza)
class EtiquetaNatureza extends StatelessWidget {
  const EtiquetaNatureza({super.key, required this.natureza});

  final String natureza;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: CoresApp.linha),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(natureza, style: const TextStyle(fontSize: 12)),
    );
  }
}
