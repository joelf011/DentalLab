import 'package:flutter/material.dart';

import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// Janela "Adicionar nota": nota interna (a clínica não a vê).
// Abre-se com: mostrarJanelaNota(context, trabalho)
Future<void> mostrarJanelaNota(BuildContext context, Trabalho trabalho) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => JanelaNota(trabalho: trabalho),
  );
}

class JanelaNota extends StatefulWidget {
  const JanelaNota({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<JanelaNota> createState() => _JanelaNotaState();
}

class _JanelaNotaState extends State<JanelaNota> {
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
              titulo: 'Adicionar nota',
              descricao: widget.trabalho.referencia,
            ),
            TextButton(onPressed: _fechar, child: const Text('Fechar')),
          ],
        ),
      ),
    );
  }
}
