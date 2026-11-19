import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda_nova.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';
import 'package:app_mobile/comum/widgets/widget_odontograma.dart';

import 'rascunho_trabalho.dart';
import 'widget_zona_ficheiros.dart';

class FormularioTrabalho extends StatefulWidget {
  const FormularioTrabalho({
    super.key,
    required this.numero,
    required this.trabalho,
    required this.tipos,
    required this.aoMudar,
    required this.aoRemover,
  });

  final int numero;
  final RascunhoTrabalho trabalho;
  final List<TipoTrabalho> tipos;
  final VoidCallback aoMudar;
  final ValueChanged<RascunhoTrabalho> aoRemover;

  @override
  State<FormularioTrabalho> createState() => _FormularioTrabalhoState();
}

class _FormularioTrabalhoState extends State<FormularioTrabalho> {
  late TextEditingController _cor;
  late TextEditingController _descricao;
  bool _aberto = true;
  bool _odontogramaAberto = false;

  @override
  void initState() {
    super.initState();
    _cor = TextEditingController(text: widget.trabalho.cor);
    _descricao = TextEditingController(text: widget.trabalho.descricao);
    _cor.addListener(_guardarTexto);
    _descricao.addListener(_guardarTexto);
  }

  @override
  void dispose() {
    _cor.dispose();
    _descricao.dispose();
    super.dispose();
  }

  void _guardarTexto() {
    widget.trabalho.cor = _cor.text;
    widget.trabalho.descricao = _descricao.text;
  }

  void _alternar() => setState(() => _aberto = !_aberto);
  void _alternarOdontograma() =>
      setState(() => _odontogramaAberto = !_odontogramaAberto);
  void _remover() => widget.aoRemover(widget.trabalho);

  void _mudarTipo(String? id) {
    if (id == null) return;
    setState(() {
      widget.trabalho.tipo = widget.tipos.firstWhere((tipo) => tipo.id == id);
    });
    widget.aoMudar();
  }

  void _mudarDentes(List<int> dentes) {
    setState(() => widget.trabalho.dentes = dentes);
  }

  void _mudarFicheiros(Map<String, String> ficheiros) {
    setState(() {
      widget.trabalho.ficheiros
        ..clear()
        ..addAll(ficheiros);
    });
  }

  void _mudarFotografias(Map<String, String> fotografias) {
    setState(() {
      widget.trabalho.fotografias
        ..clear()
        ..addAll(fotografias);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: CoresApp.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CoresApp.linha),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _alternar,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TRABALHO ${widget.numero}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: CoresApp.textoSuave,
                                  ),
                                ),
                                Text(
                                  widget.trabalho.tipo?.nome ??
                                      'Selecionar tipo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _aberto ? Icons.remove : Icons.add,
                            color: CoresApp.douradoEscuro,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _remover,
                  child: const Text(
                    'Remover',
                    style: TextStyle(color: CoresApp.erro),
                  ),
                ),
              ],
            ),
          ),
          Offstage(
            offstage: !_aberto,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  const Divider(),
                  DropdownButtonFormField<String>(
                    initialValue: widget.trabalho.tipo?.id,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de trabalho',
                    ),
                    hint: const Text('Selecionar tipo'),
                    isExpanded: true,
                    items: [
                      for (final tipo in widget.tipos)
                        DropdownMenuItem(
                          value: tipo.id,
                          child: Text(tipo.nome),
                        ),
                    ],
                    onChanged: _mudarTipo,
                  ),
                  if (widget.trabalho.tipo != null)
                    Text(
                      'Natureza: ${widget.trabalho.tipo!.natureza}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                  OutlinedButton(
                    onPressed: _alternarOdontograma,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Odontograma · ${widget.trabalho.dentes.length} selecionados',
                          ),
                        ),
                        Icon(
                          _odontogramaAberto
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                  if (_odontogramaAberto)
                    Odontograma(
                      selecionados: widget.trabalho.dentes,
                      aoMudar: _mudarDentes,
                    ),
                  CampoTexto(
                    etiqueta: 'Cor',
                    controlador: _cor,
                    dica: 'Ex: A2',
                  ),
                  CampoTexto(
                    etiqueta: 'Descrição do trabalho',
                    controlador: _descricao,
                    dica: 'Especificações e indicações para este trabalho...',
                    linhas: 4,
                  ),
                  ZonaFicheiros(
                    fotografias: false,
                    ficheiros: widget.trabalho.ficheiros,
                    aoMudar: _mudarFicheiros,
                  ),
                  ZonaFicheiros(
                    fotografias: true,
                    ficheiros: widget.trabalho.fotografias,
                    aoMudar: _mudarFotografias,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
