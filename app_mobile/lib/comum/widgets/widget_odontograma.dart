import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Mantém os mesmos parâmetros para o modo de leitura dos detalhes.
class Odontograma extends StatefulWidget {
  const Odontograma({super.key, required this.selecionados, this.aoMudar});

  final List<int> selecionados;
  final ValueChanged<List<int>>? aoMudar;

  static const superiorDireito = [18, 17, 16, 15, 14, 13, 12, 11];
  static const superiorEsquerdo = [21, 22, 23, 24, 25, 26, 27, 28];
  static const inferiorDireito = [48, 47, 46, 45, 44, 43, 42, 41];
  static const inferiorEsquerdo = [31, 32, 33, 34, 35, 36, 37, 38];

  @override
  State<Odontograma> createState() => _OdontogramaState();
}

class _OdontogramaState extends State<Odontograma> {
  void _selecionarTodos() {
    widget.aoMudar?.call([
      ...Odontograma.superiorDireito,
      ...Odontograma.superiorEsquerdo,
      ...Odontograma.inferiorDireito,
      ...Odontograma.inferiorEsquerdo,
    ]);
  }

  void _limpar() => widget.aoMudar?.call([]);

  Widget _quadrante(String legenda, List<int> dentes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          legenda,
          style: const TextStyle(fontSize: 11, color: CoresApp.textoSuave),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final dente in dentes)
              Expanded(
                child: _Dente(
                  numero: dente,
                  selecionados: widget.selecionados,
                  aoMudar: widget.aoMudar,
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordenados = widget.selecionados.toSet().toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (widget.aoMudar != null)
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _selecionarTodos,
                child: const Text('Selecionar todos'),
              ),
              OutlinedButton(
                onPressed: ordenados.isEmpty ? null : _limpar,
                child: const Text('Limpar seleção'),
              ),
            ],
          ),
        _quadrante('Superior direito', Odontograma.superiorDireito),
        _quadrante('Superior esquerdo', Odontograma.superiorEsquerdo),
        const Divider(),
        _quadrante('Inferior direito', Odontograma.inferiorDireito),
        _quadrante('Inferior esquerdo', Odontograma.inferiorEsquerdo),
        Text(
          'Selecionados: ${ordenados.isEmpty ? 'nenhum' : ordenados.join(', ')}',
          style: const TextStyle(fontSize: 12, color: CoresApp.douradoEscuro),
        ),
      ],
    );
  }
}

class _Dente extends StatefulWidget {
  const _Dente({
    required this.numero,
    required this.selecionados,
    required this.aoMudar,
  });

  final int numero;
  final List<int> selecionados;
  final ValueChanged<List<int>>? aoMudar;

  @override
  State<_Dente> createState() => _DenteState();
}

class _DenteState extends State<_Dente> {
  void _tocar() {
    final novaLista = widget.selecionados.contains(widget.numero)
        ? widget.selecionados.where((dente) => dente != widget.numero).toList()
        : [...widget.selecionados, widget.numero];
    widget.aoMudar?.call(novaLista);
  }

  @override
  Widget build(BuildContext context) {
    final selecionado = widget.selecionados.contains(widget.numero);
    return Semantics(
      label: 'Dente ${widget.numero}',
      selected: selecionado,
      button: widget.aoMudar != null,
      child: Tooltip(
        message: 'Dente ${widget.numero}',
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: selecionado ? CoresApp.dourado : CoresApp.superficie,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: CoresApp.linha),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.aoMudar == null ? null : _tocar,
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    '${widget.numero}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
