import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Etiqueta com a natureza do trabalho. Na base de dados é FISICO ou DIGITAL.
// Exemplo: EtiquetaNatureza(natureza: trabalho.natureza)
class EtiquetaNatureza extends StatelessWidget {
  const EtiquetaNatureza({super.key, required this.natureza});

  final String natureza;

  @override
  Widget build(BuildContext context) {
    final digital = natureza == 'DIGITAL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: digital ? CoresApp.infoClaro : CoresApp.fundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            digital ? Icons.assignment_outlined : Icons.inventory_2_outlined,
            size: 14,
            color: digital ? CoresApp.info : CoresApp.texto,
          ),
          const SizedBox(width: 4),
          Text(
            textoDaNatureza(natureza),
            style: TextStyle(
              fontSize: 12,
              color: digital ? CoresApp.info : CoresApp.texto,
            ),
          ),
        ],
      ),
    );
  }
}

// FISICO -> Físico, DIGITAL -> Digital
String textoDaNatureza(String natureza) =>
    natureza == 'DIGITAL' ? 'Digital' : 'Físico';
