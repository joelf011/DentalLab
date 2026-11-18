import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Contador reutilizável nos ecrãs de início.
class Contador extends StatelessWidget {
  const Contador({
    super.key,
    required this.texto,
    required this.valor,
    required this.cor,
    required this.fundo,
    required this.aoTocar,
    this.corValor,
    this.margem = const EdgeInsets.only(bottom: 10),
    this.espacamento = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.alturaMinima = 64,
    this.estiloTexto,
    this.estiloValor,
  });

  final String texto;
  final int valor;
  final Color cor;
  final Color fundo;
  final VoidCallback aoTocar;
  final Color? corValor;
  final EdgeInsetsGeometry margem;
  final EdgeInsetsGeometry espacamento;
  final double alturaMinima;
  final TextStyle? estiloTexto;
  final TextStyle? estiloValor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: fundo,
      elevation: 0,
      margin: margem,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CoresApp.linha),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: alturaMinima),
          child: Padding(
            padding: espacamento,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texto,
                    style:
                        (estiloTexto ??
                                const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ))
                            .copyWith(color: cor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$valor',
                  style:
                      (estiloValor ??
                              const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ))
                          .copyWith(color: corValor ?? cor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
