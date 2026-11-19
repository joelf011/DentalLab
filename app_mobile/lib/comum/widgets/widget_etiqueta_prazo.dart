import 'package:flutter/material.dart';

import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

// Etiqueta com o prazo de entrega: "3d", "2d atraso" ou "Concluído",
// e a data por baixo. O estado é o da ordem (tabela estado_ordem).
// Exemplo: EtiquetaPrazo(prazo: encomenda.prazoEntrega!, estado: encomenda.estado)
class EtiquetaPrazo extends StatelessWidget {
  const EtiquetaPrazo({super.key, required this.prazo, required this.estado});

  final DateTime prazo;
  final String estado;

  bool get _fechada =>
      estado == 'Concluído' || estado == 'Entregue' || estado == 'Rejeitado';

  @override
  Widget build(BuildContext context) {
    final dias = diasAte(prazo);
    final String texto;
    final Color corTexto;
    final Color corFundo;

    if (_fechada) {
      texto = estado;
      corTexto = CoresApp.textoForte;
      corFundo = CoresApp.fundo;
    } else if (dias < 0) {
      texto = '${-dias}d atraso';
      corTexto = CoresApp.erro;
      corFundo = CoresApp.erroClaro;
    } else if (dias <= 2) {
      texto = '${dias}d';
      corTexto = CoresApp.erro;
      corFundo = CoresApp.erroClaro;
    } else if (dias <= 5) {
      texto = '${dias}d';
      corTexto = CoresApp.douradoEscuro;
      corFundo = CoresApp.douradoClaro;
    } else {
      texto = '${dias}d';
      corTexto = CoresApp.textoForte;
      corFundo = CoresApp.fundo;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
          Text(
            dataCurta(prazo),
            style: TextStyle(fontSize: 10, color: corTexto),
          ),
        ],
      ),
    );
  }
}
