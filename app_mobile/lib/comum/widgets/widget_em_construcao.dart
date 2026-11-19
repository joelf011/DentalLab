import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Conteúdo provisório dos ecrãs que ainda estão a ser desenvolvidos.
class EmConstrucao extends StatelessWidget {
  const EmConstrucao({super.key, required this.titulo, this.descricao});

  final String titulo;
  final String? descricao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 40, color: CoresApp.dourado),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: CoresApp.textoForte),
            ),
            const SizedBox(height: 8),
            const Text(
              'Em construção',
              style: TextStyle(fontSize: 13, color: CoresApp.textoSuave),
            ),
            if (descricao != null) ...[
              const SizedBox(height: 8),
              Text(
                descricao!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: CoresApp.textoSuave,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
