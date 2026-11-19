import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Etiqueta com o estado de uma encomenda / trabalho.
//
// Estados: por_receber, encaminhado, em_producao, em_standby,
//          aguarda_aprovacao, concluido
//
// paraClinica: true  -> textos da clínica (Iniciar / Processamento / Concluído)
// paraClinica: false -> textos do laboratório (Em avaliação, Por iniciar, ...)
//
// Exemplo: EtiquetaEstado(estado: encomenda.estado, paraClinica: true)
class EtiquetaEstado extends StatelessWidget {
  const EtiquetaEstado({
    super.key,
    required this.estado,
    this.paraClinica = false,
  });

  final String estado;
  final bool paraClinica;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CoresApp.douradoClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        textoDoEstado(estado, paraClinica: paraClinica),
        style: const TextStyle(fontSize: 12, color: CoresApp.textoForte),
      ),
    );
  }
}

// Texto de cada estado. Também serve para filtros e títulos.
String textoDoEstado(String estado, {bool paraClinica = false}) {
  if (paraClinica) {
    return switch (estado) {
      'por_receber' || 'encaminhado' => 'Iniciar',
      'concluido' => 'Concluído',
      _ => 'Processamento',
    };
  }
  return switch (estado) {
    'por_receber' => 'Em avaliação',
    'encaminhado' => 'Por iniciar',
    'em_producao' => 'Em processamento',
    'em_standby' => 'Em espera',
    'aguarda_aprovacao' => 'Em prova',
    'concluido' => 'Concluído',
    _ => estado,
  };
}
