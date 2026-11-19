import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Mensagem para listas vazias ("Sem resultados", "Sem notificações", ...).
// Exemplo: EstadoVazio(mensagem: 'Sem resultados', dica: 'Tente ajustar os filtros')
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.mensagem,
    this.dica,
    this.icone = Icons.inbox_outlined,
  });

  final String mensagem;
  final String? dica;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 40, color: CoresApp.linha),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: CoresApp.textoSuave),
          ),
          if (dica != null) ...[
            const SizedBox(height: 4),
            Text(
              dica!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: CoresApp.textoSuave),
            ),
          ],
        ],
      ),
    );
  }
}
