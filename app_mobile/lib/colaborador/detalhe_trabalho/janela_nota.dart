import 'package:flutter/material.dart';

import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/widget_cabecalho_janela.dart';
import 'package:app_mobile/comum/validacoes.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';

// Janela "Adicionar Nota": nota interna do trabalho (a clínica não a vê).
//
// Abre-se com: mostrarJanelaNota(context, trabalho)
Future<void> mostrarJanelaNota(BuildContext context, Trabalho trabalho) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => JanelaNota(trabalho: trabalho),
  );
}

class JanelaNota extends StatefulWidget {
  const JanelaNota({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<JanelaNota> createState() => _JanelaNotaState();
}

class _JanelaNotaState extends State<JanelaNota> {
  final _servidor = const ServidorColaborador();
  final _formulario = GlobalKey<FormState>();
  late TextEditingController _controladorNota;
  bool _aGuardar = false;

  @override
  void initState() {
    super.initState();
    _controladorNota = TextEditingController();
  }

  @override
  void dispose() {
    _controladorNota.dispose();
    super.dispose();
  }

  void _fechar() {
    Navigator.pop(context);
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _aGuardar = true;
    });
    await _servidor.adicionarNota(
      widget.trabalho.id,
      _controladorNota.text.trim(),
    );
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro.showSnackBar(const SnackBar(content: Text('Nota adicionada')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                CabecalhoJanela(titulo: 'Adicionar Nota', aoFechar: _fechar),
                CampoTexto(
                  etiqueta: 'Nota interna',
                  controlador: _controladorNota,
                  dica: 'Escreva a nota...',
                  linhas: 4,
                  validador: validarObrigatorio,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _aGuardar ? null : _fechar,
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _aGuardar ? null : _guardar,
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
