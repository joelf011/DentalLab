import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Campo de texto com a etiqueta por cima, como nos formulários do protótipo.
// O controlador é criado no initState e libertado no dispose de quem o usa.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.dica,
    this.teclado,
    this.oculto = false,
    this.linhas = 1,
    this.validador,
    this.aoSubmeter,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final String? dica;
  final TextInputType? teclado;
  final bool oculto;
  final int linhas;
  final FormFieldValidator<String>? validador;
  final ValueChanged<String>? aoSubmeter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.1,
            color: CoresApp.textoSuave,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controlador,
          keyboardType: teclado,
          obscureText: oculto,
          maxLines: linhas,
          validator: validador,
          onFieldSubmitted: aoSubmeter,
          decoration: InputDecoration(
            hintText: dica,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CoresApp.linha),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CoresApp.dourado),
            ),
          ),
        ),
      ],
    );
  }
}
