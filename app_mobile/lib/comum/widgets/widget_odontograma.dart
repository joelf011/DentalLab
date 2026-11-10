import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Odontograma com a numeração FDI (11 a 48).
//
// Só para ver:      Odontograma(selecionados: encomenda.dentes)
// Para escolher:    Odontograma(selecionados: _dentes, aoMudar: _mudarDentes)
class Odontograma extends StatelessWidget {
  const Odontograma({super.key, required this.selecionados, this.aoMudar});

  final List<int> selecionados;

  // Se for null, o odontograma é só de leitura.
  final ValueChanged<List<int>>? aoMudar;

  static const superiorDireito = [18, 17, 16, 15, 14, 13, 12, 11];
  static const superiorEsquerdo = [21, 22, 23, 24, 25, 26, 27, 28];
  static const inferiorDireito = [48, 47, 46, 45, 44, 43, 42, 41];
  static const inferiorEsquerdo = [31, 32, 33, 34, 35, 36, 37, 38];

  @override
  Widget build(BuildContext context) {
    final linhas = [
      superiorDireito,
      superiorEsquerdo,
      inferiorDireito,
      inferiorEsquerdo,
    ];
    return Column(
      children: [
        for (final linha in linhas)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final dente in linha)
                _Dente(
                  numero: dente,
                  selecionado: selecionados.contains(dente),
                  selecionados: selecionados,
                  aoMudar: aoMudar,
                ),
            ],
          ),
      ],
    );
  }
}

class _Dente extends StatelessWidget {
  const _Dente({
    required this.numero,
    required this.selecionado,
    required this.selecionados,
    required this.aoMudar,
  });

  final int numero;
  final bool selecionado;
  final List<int> selecionados;
  final ValueChanged<List<int>>? aoMudar;

  // Junta ou tira este dente da lista e avisa quem usa o odontograma.
  void _tocar() {
    final novaLista = selecionado
        ? selecionados.where((dente) => dente != numero).toList()
        : [...selecionados, numero];
    aoMudar!(novaLista);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoMudar == null ? null : _tocar,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? CoresApp.dourado : CoresApp.superficie,
          border: Border.all(color: CoresApp.linha),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$numero', style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
