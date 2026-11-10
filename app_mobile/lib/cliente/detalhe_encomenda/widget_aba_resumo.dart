import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_linha_informacao.dart';
import 'package:app_mobile/comum/widgets/widget_odontograma.dart';

// Aba "Resumo": dados principais, descrição e odontograma (só leitura).
class AbaResumo extends StatelessWidget {
  const AbaResumo({super.key, required this.encomenda});

  final Encomenda encomenda;

  @override
  Widget build(BuildContext context) {
    final prazo = encomenda.prazo;
    final descricao = encomenda.descricao;
    final dentesOrdenados = [...encomenda.dentes]..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinhaInformacao(etiqueta: 'Médico', valor: encomenda.medico),
                LinhaInformacao(
                  etiqueta: 'Identificação',
                  valor: encomenda.paciente,
                ),
                LinhaInformacao(
                  etiqueta: 'Material',
                  valor: encomenda.material,
                ),
                LinhaInformacao(etiqueta: 'Cor', valor: encomenda.cor),
                LinhaInformacao(
                  etiqueta: 'Prazo',
                  valor: prazo == null ? null : dataCompleta(prazo),
                ),
              ],
            ),
          ),
        ),
        if (descricao != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESCRIÇÃO',
                    style: TextStyle(fontSize: 12, color: CoresApp.textoSuave),
                  ),
                  const SizedBox(height: 8),
                  Text(descricao, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
        if (encomenda.dentes.isNotEmpty)
          Card(
            child: ExpansionTile(
              title: const Text('Ver odontograma'),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Odontograma(selecionados: encomenda.dentes),
                const SizedBox(height: 8),
                Text(
                  'Dentes: ${dentesOrdenados.join(', ')}',
                  style: const TextStyle(color: CoresApp.douradoEscuro),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
