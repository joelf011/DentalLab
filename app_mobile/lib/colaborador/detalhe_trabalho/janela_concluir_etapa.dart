import 'package:flutter/material.dart';

import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// Janela "Concluir Etapa": etapa atual -> próxima etapa, a quem atribuir
// (livre / a mim / outro colaborador), nota interna e destino
// (avançar / prova clínica / standby).
//
// Abre-se com: mostrarJanelaConcluirEtapa(context, trabalho)
Future<void> mostrarJanelaConcluirEtapa(
  BuildContext context,
  Trabalho trabalho,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => JanelaConcluirEtapa(trabalho: trabalho),
  );
}

class JanelaConcluirEtapa extends StatefulWidget {
  const JanelaConcluirEtapa({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<JanelaConcluirEtapa> createState() => _JanelaConcluirEtapaState();
}

class _JanelaConcluirEtapaState extends State<JanelaConcluirEtapa> {
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
              titulo: 'Concluir Etapa',
              descricao: widget.trabalho.referencia,
            ),
            TextButton(onPressed: _fechar, child: const Text('Fechar')),
          ],
        ),
      ),
    );
  }
}
