import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/servidor_autenticacao.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/validacoes.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';
import 'package:app_mobile/comum/widgets/widget_logotipo.dart';

// Início de sessão. Conforme o perfil, abre a vista da clínica ou a do colaborador.
class PaginaLogin extends StatefulWidget {
  const PaginaLogin({super.key});

  @override
  State<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends State<PaginaLogin> {
  final _servidor = const ServidorAutenticacao();
  final _formulario = GlobalKey<FormState>();
  late TextEditingController _controladorEmail;
  late TextEditingController _controladorPalavraPasse;
  bool _aEntrar = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _controladorEmail = TextEditingController();
    _controladorPalavraPasse = TextEditingController();
  }

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorPalavraPasse.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _aEntrar = true;
      _erro = null;
    });
    try {
      final sessao = await _servidor.entrar(
        _controladorEmail.text,
        _controladorPalavraPasse.text,
      );
      if (!mounted) return;
      if (sessao == null) {
        setState(() {
          _aEntrar = false;
          _erro = 'Credenciais inválidas.';
        });
        return;
      }
      // Guarda quem entrou e abre a vista certa.
      Sessao.atual = sessao;
      if (sessao.perfil == Perfil.cliente) {
        context.go(Rotas.cliente);
      } else {
        context.go(Rotas.colaborador);
      }
    } on Exception catch (erro) {
      if (!mounted) return;
      setState(() {
        _aEntrar = false;
        _erro = erro.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Enter no campo da palavra-passe também faz login.
  void _submeter(String valor) {
    _entrar();
  }

  void _registarClinica() {
    context.push(Rotas.registo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: Logotipo(largura: 190)),
                    const SizedBox(height: 8),
                    const Text(
                      'LABORATÓRIO DE PRÓTESE DENTÁRIA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.8,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bem-vindo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 22,
                        color: CoresApp.textoForte,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CampoTexto(
                      etiqueta: 'E-mail ou utilizador',
                      controlador: _controladorEmail,
                      dica: 'E-mail, clinica ou colaborador',
                      teclado: TextInputType.emailAddress,
                      validador: validarObrigatorio,
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      etiqueta: 'Palavra-passe',
                      controlador: _controladorPalavraPasse,
                      dica: '••••••••',
                      oculto: true,
                      validador: validarObrigatorio,
                      aoSubmeter: _submeter,
                    ),
                    if (_erro != null) _CaixaErro(mensagem: _erro!),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _aEntrar ? null : _entrar,
                      child: Text(_aEntrar ? 'A verificar...' : 'Entrar'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _registarClinica,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CoresApp.douradoEscuro,
                        side: const BorderSide(color: CoresApp.dourado),
                      ),
                      child: const Text('Registar clínica'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Crie a conta da sua clínica ou consultório.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Caixa vermelha com a mensagem de erro do login.
class _CaixaErro extends StatelessWidget {
  const _CaixaErro({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.erroClaro,
        border: Border.all(color: CoresApp.erro),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        mensagem,
        style: const TextStyle(fontSize: 14, color: CoresApp.erro),
      ),
    );
  }
}
