import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';

// Aba "Progresso": avanço da encomenda a partir do estado da ordem.
// A clínica não vê as etapas, que são internas do laboratório.
class AbaProgresso extends StatelessWidget {
  const AbaProgresso({super.key, required this.encomenda});

  final Encomenda encomenda;

  int _percentagem() {
    return switch (encomenda.estado) {
      'Em avaliação' => 10,
      'Por iniciar' => 25,
      'Em processamento' || 'Em espera' => 50,
      'Em prova' => 75,
      'Concluído' || 'Entregue' => 100,
      _ => 0,
    };
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
