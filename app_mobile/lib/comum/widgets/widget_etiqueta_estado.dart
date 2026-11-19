import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Etiqueta com o estado de uma encomenda, com os estados da tabela estado_ordem:
// Em avaliação, Rejeitado, Por iniciar, Em processamento, Em espera, Em prova,
// Concluído e Entregue.
//
// paraClinica: true  -> textos simples da clínica (Iniciar, Processamento, ...)
// paraClinica: false -> o estado tal como está na base de dados
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
    final corTexto = _corDoTexto();
    final corFundo = _corDoFundo();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: corTexto, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          // Flexible: num espaço apertado o texto acaba em "..." em vez de sair fora.
          Flexible(
            child: Text(
              textoDoEstado(estado, paraClinica: paraClinica),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: corTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Grupo de cor de cada estado (cores do protótipo).
  String _grupoDeCor() {
    if (paraClinica) {
      return switch (textoDoEstado(estado, paraClinica: true)) {
        'Iniciar' => 'dourado',
        'Processamento' => 'azul',
        'Concluído' => 'verde',
        _ => 'vermelho',
      };
    }
    return switch (estado) {
      'Em processamento' => 'azul',
      'Em espera' => 'laranja',
      'Concluído' || 'Entregue' => 'verde',
      'Rejeitado' => 'vermelho',
      _ => 'dourado', // Em avaliação, Por iniciar, Em prova
    };
  }

  Color _corDoTexto() {
    return switch (_grupoDeCor()) {
      'azul' => CoresApp.info,
      'laranja' => CoresApp.aviso,
      'verde' => CoresApp.sucesso,
      'vermelho' => CoresApp.erro,
      _ => CoresApp.douradoEscuro,
    };
  }

  Color _corDoFundo() {
    return switch (_grupoDeCor()) {
      'azul' => CoresApp.infoClaro,
      'laranja' => CoresApp.avisoClaro,
      'verde' => CoresApp.sucessoClaro,
      'vermelho' => CoresApp.erroClaro,
      _ => CoresApp.douradoClaro,
    };
  }
}

// Texto de cada estado. Também serve para os filtros e os contadores.
String textoDoEstado(String estado, {bool paraClinica = false}) {
  if (!paraClinica) return estado;
  return switch (estado) {
    'Em avaliação' || 'Por iniciar' => 'Iniciar',
    'Em processamento' || 'Em espera' || 'Em prova' => 'Processamento',
    'Concluído' || 'Entregue' => 'Concluído',
    _ => estado, // Rejeitado
  };
}
