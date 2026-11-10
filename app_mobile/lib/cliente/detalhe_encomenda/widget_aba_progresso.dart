import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';

// Aba "Progresso": estado geral da encomenda e percentagem.
// A clínica não vê as etapas internas, só o avanço total.
class AbaProgresso extends StatelessWidget {
  const AbaProgresso({super.key, required this.encomenda});

  final Encomenda encomenda;

  // Concluída: 100 %. Por iniciar: 10 %. Em curso: etapas feitas, entre 35 e 90 %.
  int _percentagem() {
    final estado = encomenda.estado;
    if (estado == 'concluido') return 100;
    if (estado == 'por_receber' || estado == 'encaminhado') return 10;
    final etapas = encomenda.etapas;
    if (etapas.isEmpty) return 50;
    final feitas = etapas.where((etapa) => etapa.concluida).length;
    final calculada = (feitas / etapas.length * 100).round();
    return calculada.clamp(35, 90);
  }

  @override
  Widget build(BuildContext context) {
    final percentagem = _percentagem();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTADO ATUAL',
                  style: TextStyle(fontSize: 12, color: CoresApp.textoSuave),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        textoDoEstado(encomenda.estado, paraClinica: true),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$percentagem%',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: CoresApp.douradoEscuro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: percentagem / 100,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: CoresApp.linha,
                  color: CoresApp.dourado,
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Encomenda recebida',
                        style: TextStyle(
                          fontSize: 12,
                          color: CoresApp.textoSuave,
                        ),
                      ),
                    ),
                    Text(
                      'Conclusão',
                      style: TextStyle(
                        fontSize: 12,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
