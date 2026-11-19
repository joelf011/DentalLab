import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Título das janelas do detalhe do trabalho, com o botão "✕" para fechar.
// Exemplo: CabecalhoJanela(titulo: 'Adicionar Nota', aoFechar: _fechar)
class CabecalhoJanela extends StatelessWidget {
  const CabecalhoJanela({
    super.key,
    required this.titulo,
    required this.aoFechar,
  });

  final String titulo;
  final VoidCallback aoFechar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.textoForte,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Fechar',
              onPressed: aoFechar,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 12),
      ],
    );
  }
}
