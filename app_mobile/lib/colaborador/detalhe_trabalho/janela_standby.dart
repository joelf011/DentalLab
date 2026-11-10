import 'package:flutter/material.dart';

import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// Janela "Colocar em standby": justificação obrigatória.
//
// Abre-se com: mostrarJanelaStandby(context, trabalho)
Future<void> mostrarJanelaStandby(BuildContext context, Trabalho trabalho) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => JanelaStandby(trabalho: trabalho),
  );
}

class JanelaStandby extends StatefulWidget {
  const JanelaStandby({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<JanelaStandby> createState() => _JanelaStandbyState();
}

class _JanelaStandbyState extends State<JanelaStandby> {
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
              titulo: 'Colocar em standby',
              descricao: widget.trabalho.referencia,
            ),
            TextButton(onPressed: _fechar, child: const Text('Fechar')),
          ],
        ),
      ),
    );
  }
}
