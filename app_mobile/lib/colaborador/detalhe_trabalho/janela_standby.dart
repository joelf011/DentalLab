import 'package:flutter/material.dart';

import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/widget_cabecalho_janela.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';

// Janela "Colocar em standby": a ordem fica "Em espera" com o motivo
// (justificação obrigatória) e a etapa atual fica suspensa.
//
// Abre-se com: mostrarJanelaStandby(context, trabalho)
Future<void> mostrarJanelaStandby(BuildContext context, Trabalho trabalho) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => JanelaStandby(trabalho: trabalho),
  );
}

class JanelaStandby extends StatefulWidget {
  const JanelaStandby({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<JanelaStandby> createState() => _JanelaStandbyState();
}

class _JanelaStandbyState extends State<JanelaStandby> {
  final _servidor = const ServidorColaborador();
  final _formulario = GlobalKey<FormState>();
  late TextEditingController _controladorMotivo;
  bool _aGuardar = false;

  @override
  void initState() {
    super.initState();
    _controladorMotivo = TextEditingController();
  }

  @override
  void dispose() {
    _controladorMotivo.dispose();
    super.dispose();
  }

  void _fechar() {
    Navigator.pop(context);
  }

  String? _validarMotivo(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'A justificação é obrigatória para standby.';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _aGuardar = true;
    });
    await _servidor.colocarEmEspera(
      widget.trabalho.ordemTrabalhoId,
      _controladorMotivo.text.trim(),
    );
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro.showSnackBar(
      const SnackBar(content: Text('Trabalho colocado em standby')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etapaAtual = widget.trabalho.etapaAtual?.nome ?? '—';
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
                CabecalhoJanela(
                  titulo: 'Colocar em standby',
                  aoFechar: _fechar,
                ),
                Text(
                  'Etapa atual: $etapaAtual',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Indique o motivo da pausa. A etapa atual fica suspensa, '
                  'sem avançar para a próxima.',
                  style: TextStyle(fontSize: 13, color: CoresApp.textoSuave),
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  etiqueta: 'Justificação obrigatória',
                  controlador: _controladorMotivo,
                  dica:
                      'Explique porque precisa de colocar o trabalho em standby…',
                  linhas: 4,
                  validador: _validarMotivo,
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
                        style: FilledButton.styleFrom(
                          backgroundColor: CoresApp.aviso,
                          foregroundColor: CoresApp.superficie,
                        ),
                        child: const Text('Colocar em standby'),
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
