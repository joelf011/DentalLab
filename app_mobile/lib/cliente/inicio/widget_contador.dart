import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Um dos 3 contadores do topo.
class Contador extends StatelessWidget {
  const Contador({
    super.key,
    required this.texto,
    required this.valor,
    required this.cor,
    required this.fundo,
    required this.aoTocar,
  });

  final String texto;
  final int valor;
  final Color cor;
  final Color fundo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: fundo,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CoresApp.linha),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texto,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$valor',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
