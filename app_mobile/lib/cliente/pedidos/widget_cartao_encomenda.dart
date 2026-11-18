import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';

// Cartão de uma encomenda (Início e Pedidos): identificação, tipo,
// estado e data de entrega. Ao tocar chama aoAbrir(encomenda).
class CartaoEncomenda extends StatelessWidget {
  const CartaoEncomenda({
    super.key,
    required this.encomenda,
    required this.aoAbrir,
  });

  final Encomenda encomenda;
  final ValueChanged<Encomenda> aoAbrir;

  void _abrir() {
    aoAbrir(encomenda);
  }

  @override
  Widget build(BuildContext context) {
    final prazo = encomenda.prazo;
    return Card(
      color: CoresApp.superficie,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CoresApp.linha),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abrir,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      encomenda.paciente,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CoresApp.textoForte,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right,
                    color: CoresApp.douradoEscuro,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                encomenda.tipo,
                style: const TextStyle(
                  fontSize: 14,
                  color: CoresApp.textoSuave,
                ),
              ),
              const SizedBox(height: 10),
              // Wrap: se não couber numa linha, a data passa para baixo.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  EtiquetaEstado(estado: encomenda.estado, paraClinica: true),
                  if (prazo != null)
                    Text(
                      'Prazo ${dataCurta(prazo)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
