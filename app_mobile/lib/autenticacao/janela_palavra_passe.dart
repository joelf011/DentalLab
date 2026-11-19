import 'package:flutter/material.dart';

import 'package:app_mobile/autenticacao/dados/servidor_autenticacao.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/validacoes.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';

// Janela "Alterar palavra-passe" (Conta da clínica e Perfil do colaborador).
//
// Abre-se com: mostrarJanelaPalavraPasse(context)
Future<void> mostrarJanelaPalavraPasse(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const JanelaPalavraPasse(),
  );
}

class JanelaPalavraPasse extends StatefulWidget {
  const JanelaPalavraPasse({super.key});

  @override
  State<JanelaPalavraPasse> createState() => _JanelaPalavraPasseState();
}

class _JanelaPalavraPasseState extends State<JanelaPalavraPasse> {
  final _servidor = const ServidorAutenticacao();
  final _formulario = GlobalKey<FormState>();
  late TextEditingController _controladorAtual;
  late TextEditingController _controladorNova;
  late TextEditingController _controladorConfirmar;
  bool _aGuardar = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _controladorAtual = TextEditingController();
    _controladorNova = TextEditingController();
    _controladorConfirmar = TextEditingController();
  }

  @override
  void dispose() {
    _controladorAtual.dispose();
    _controladorNova.dispose();
    _controladorConfirmar.dispose();
    super.dispose();
  }

  // Pelo menos 8 caracteres e diferente da atual.
  String? _validarNova(String? valor) {
    final erro = validarPalavraPasse(valor);
    if (erro != null) return erro;
    if (valor == _controladorAtual.text) {
      return 'Tem de ser diferente da palavra-passe atual.';
    }
    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if (valor != _controladorNova.text) {
      return 'As palavras-passe não coincidem.';
    }
    return null;
  }

  void _fechar() {
    Navigator.pop(context);
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _aGuardar = true;
      _erro = null;
    });
    try {
      await _servidor.alterarPalavraPasse(
        _controladorAtual.text,
        _controladorNova.text,
      );
      if (!mounted) return;
      final mensageiro = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Palavra-passe alterada')),
      );
    } on Exception catch (erro) {
      if (!mounted) return;
      setState(() {
        _aGuardar = false;
        _erro = erro.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Alterar palavra-passe',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          color: CoresApp.textoForte,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: _fechar,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  etiqueta: 'Palavra-passe atual',
                  controlador: _controladorAtual,
                  oculto: true,
                  validador: validarObrigatorio,
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  etiqueta: 'Nova palavra-passe',
                  controlador: _controladorNova,
                  dica: 'Mínimo 8 caracteres',
                  oculto: true,
                  validador: _validarNova,
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  etiqueta: 'Confirmar nova palavra-passe',
                  controlador: _controladorConfirmar,
                  oculto: true,
                  validador: _validarConfirmacao,
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 16),
                  Text(_erro!, style: const TextStyle(color: CoresApp.erro)),
                ],
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
                        child: Text(_aGuardar ? 'A guardar...' : 'Guardar'),
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
