import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Linha "ETIQUETA   valor", usada nos resumos e perfis. Sem valor mostra "—".
// Exemplo: LinhaInformacao(etiqueta: 'Médico', valor: encomenda.medico)
class LinhaInformacao extends StatelessWidget {
  const LinhaInformacao({super.key, required this.etiqueta, this.valor});

  final String etiqueta;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    final temValor = valor != null && valor!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              etiqueta.toUpperCase(),
              style: const TextStyle(fontSize: 12, color: CoresApp.textoSuave),
            ),
          ),
          Expanded(
            child: Text(
              temValor ? valor! : '—',
              style: const TextStyle(fontSize: 14, color: CoresApp.textoForte),
            ),
          ),
        ],
      ),
    );
  }
}
