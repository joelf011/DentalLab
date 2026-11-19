import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_natureza.dart';
import 'package:app_mobile/comum/widgets/widget_linha_informacao.dart';
import 'package:app_mobile/comum/widgets/widget_odontograma.dart';

// Aba "Resumo": dados da encomenda (paciente e médico) e os seus trabalhos.
class AbaResumo extends StatelessWidget {
  const AbaResumo({super.key, required this.encomenda});

  final Encomenda encomenda;

  String? _textoPaciente() {
    final partes = [
      if (encomenda.sexoPaciente == 'M') 'Masculino',
      if (encomenda.sexoPaciente == 'F') 'Feminino',
      if (encomenda.idadePaciente != null) '${encomenda.idadePaciente} anos',
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final prazo = encomenda.prazoEntrega;
    final consulta = encomenda.dataProximaConsulta;
    final motivo = encomenda.motivoRejeicao ?? encomenda.motivoEspera;
    final observacoes = encomenda.observacoes;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (motivo != null)
          _CaixaMotivo(estado: encomenda.estado, motivo: motivo),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinhaInformacao(etiqueta: 'Médico', valor: encomenda.medico),
                LinhaInformacao(
                  etiqueta: 'Paciente',
                  valor: encomenda.paciente,
                ),
                LinhaInformacao(
                  etiqueta: 'Sexo / idade',
                  valor: _textoPaciente(),
                ),
                LinhaInformacao(
                  etiqueta: 'Próxima consulta',
                  valor: consulta == null ? null : dataCompleta(consulta),
                ),
                LinhaInformacao(
                  etiqueta: 'Prazo',
                  valor: prazo == null ? null : dataCompleta(prazo),
                ),
              ],
            ),
          ),
        ),
        if (observacoes != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OBSERVAÇÕES',
                    style: TextStyle(fontSize: 12, color: CoresApp.textoSuave),
                  ),
                  const SizedBox(height: 8),
                  Text(observacoes, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'TRABALHOS (${encomenda.trabalhos.length})',
          style: const TextStyle(fontSize: 12, color: CoresApp.textoSuave),
        ),
        const SizedBox(height: 8),
        for (final trabalho in encomenda.trabalhos)
          _CartaoTrabalho(trabalho: trabalho),
      ],
    );
  }
}

// Um trabalho da encomenda: tipo, natureza, cor e odontograma.
class _CartaoTrabalho extends StatelessWidget {
  const _CartaoTrabalho({required this.trabalho});

  final TrabalhoEncomenda trabalho;

  @override
  Widget build(BuildContext context) {
    final dentesOrdenados = [...trabalho.dentes]..sort();
    final cor = trabalho.cor;
    return Card(
      child: ExpansionTile(
        title: Text(trabalho.tipoTrabalho),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              EtiquetaNatureza(natureza: trabalho.natureza),
              if (cor != null) ...[const SizedBox(width: 8), Text('Cor $cor')],
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          if (trabalho.dentes.isEmpty)
            const Text('Sem dentes indicados.')
          else ...[
            Odontograma(selecionados: trabalho.dentes),
            const SizedBox(height: 8),
            Text(
              'Dentes: ${dentesOrdenados.join(', ')}',
              style: const TextStyle(color: CoresApp.douradoEscuro),
            ),
          ],
        ],
      ),
    );
  }
}

// Aviso com o motivo da rejeição ou da espera.
class _CaixaMotivo extends StatelessWidget {
  const _CaixaMotivo({required this.estado, required this.motivo});

  final String estado;
  final String motivo;

  @override
  Widget build(BuildContext context) {
    final rejeitada = estado == 'Rejeitado';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rejeitada ? CoresApp.erroClaro : CoresApp.avisoClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rejeitada ? 'Encomenda rejeitada: $motivo' : 'Em espera: $motivo',
        style: TextStyle(color: rejeitada ? CoresApp.erro : CoresApp.aviso),
      ),
    );
  }
}
