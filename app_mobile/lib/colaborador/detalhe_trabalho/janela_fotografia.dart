import 'package:flutter/material.dart';

import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// Janela "Adicionar fotografia": Câmara ou Galeria (package image_picker).
// Abre-se com: mostrarJanelaFotografia(context, trabalho)
Future<void> mostrarJanelaFotografia(BuildContext context, Trabalho trabalho) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => JanelaFotografia(trabalho: trabalho),
  );
}

class JanelaFotografia extends StatefulWidget {
  const JanelaFotografia({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<JanelaFotografia> createState() => _JanelaFotografiaState();
}

class _JanelaFotografiaState extends State<JanelaFotografia> {
  void _fechar() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmConstrucao(
              titulo: 'Adicionar fotografia',
              descricao: widget.trabalho.referencia,
            ),
            TextButton(onPressed: _fechar, child: const Text('Fechar')),
          ],
        ),
      ),
    );
  }
}
