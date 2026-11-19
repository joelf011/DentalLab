import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/servidor_autenticacao.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/validacoes.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';

// Registo de clínica em 2 passos: dados da clínica e dados de acesso.
class PaginaRegisto extends StatefulWidget {
  const PaginaRegisto({super.key});

  @override
  State<PaginaRegisto> createState() => _PaginaRegistoState();
}

class _PaginaRegistoState extends State<PaginaRegisto> {
  final _servidor = const ServidorAutenticacao();
  final _formulario = GlobalKey<FormState>();
  late TextEditingController _controladorNome;
  late TextEditingController _controladorMorada;
  late TextEditingController _controladorNif;
  late TextEditingController _controladorContacto;
  late TextEditingController _controladorEmail;
  late TextEditingController _controladorPalavraPasse;
  int _passo = 1;
  bool _aRegistar = false;

  @override
  void initState() {
    super.initState();
    _controladorNome = TextEditingController();
    _controladorMorada = TextEditingController();
    _controladorNif = TextEditingController();
    _controladorContacto = TextEditingController();
    _controladorEmail = TextEditingController();
    _controladorPalavraPasse = TextEditingController();
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorMorada.dispose();
    _controladorNif.dispose();
    _controladorContacto.dispose();
    _controladorEmail.dispose();
    _controladorPalavraPasse.dispose();
    super.dispose();
  }

  void _voltar() {
    if (_passo == 1) {
      context.pop();
    } else {
      setState(() {
        _passo = 1;
      });
    }
  }

  void _continuar() {
    if (!_formulario.currentState!.validate()) return;
    if (_passo == 1) {
      setState(() {
        _passo = 2;
      });
    } else {
      _registar();
    }
  }

  Future<void> _registar() async {
    setState(() {
      _aRegistar = true;
    });
    try {
      await _servidor.registarClinica(
        nome: _controladorNome.text,
        nif: _controladorNif.text,
        morada: _controladorMorada.text,
        telefone: _controladorContacto.text,
        email: _controladorEmail.text,
        palavraPasse: _controladorPalavraPasse.text,
      );
      if (!mounted) return;
      context.go(Rotas.pendente);
    } on Exception catch (erro) {
      if (!mounted) return;
      setState(() {
        _aRegistar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String textoBotao;
    if (_passo == 1) {
      textoBotao = 'Continuar';
    } else if (_aRegistar) {
      textoBotao = 'A registar...';
    } else {
      textoBotao = 'Registar';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: _voltar,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PASSO $_passo DE 2',
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: CoresApp.textoSuave,
              ),
            ),
            Text(
              _passo == 1 ? 'Dados da clínica' : 'Dados de acesso',
              style: const TextStyle(fontFamily: 'serif', fontSize: 16),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _BarraPassos(passo: _passo),
            const SizedBox(height: 24),
            if (_passo == 1) ..._camposDaClinica() else ..._camposDeAcesso(),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _aRegistar ? null : _continuar,
              child: Text(textoBotao),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _camposDaClinica() {
    return [
      CampoTexto(
        etiqueta: 'Nome da clínica / consultório',
        controlador: _controladorNome,
        dica: 'Ex: Clínica Dental XYZ',
        validador: validarObrigatorio,
      ),
      const SizedBox(height: 16),
      CampoTexto(
        etiqueta: 'Morada',
        controlador: _controladorMorada,
        dica: 'Rua, nº, código postal, cidade',
      ),
      const SizedBox(height: 16),
      CampoTexto(
        etiqueta: 'NIF',
        controlador: _controladorNif,
        dica: 'PT 500 000 000',
        teclado: TextInputType.number,
      ),
      const SizedBox(height: 16),
      CampoTexto(
        etiqueta: 'Contacto',
        controlador: _controladorContacto,
        dica: '+351 200 000 000',
        teclado: TextInputType.phone,
      ),
    ];
  }

  List<Widget> _camposDeAcesso() {
    return [
      CampoTexto(
        etiqueta: 'E-mail',
        controlador: _controladorEmail,
        dica: 'nome@clinica.pt',
        teclado: TextInputType.emailAddress,
        validador: validarEmail,
      ),
      const SizedBox(height: 16),
      CampoTexto(
        etiqueta: 'Palavra-passe',
        controlador: _controladorPalavraPasse,
        dica: 'Mínimo 8 caracteres',
        oculto: true,
        validador: validarPalavraPasse,
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CoresApp.superficie,
          border: Border.all(color: CoresApp.linha),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Após o registo, a sua conta ficará pendente de validação pelo '
          'laboratório Catarina Domingos. Toda a conta fica sujeita a '
          'aprovação do laboratório.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: CoresApp.textoSuave,
          ),
        ),
      ),
    ];
  }
}

// Barra com 2 segmentos que mostra o passo atual.
class _BarraPassos extends StatelessWidget {
  const _BarraPassos({required this.passo});

  final int passo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var numero = 1; numero <= 2; numero++)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: numero <= passo ? CoresApp.dourado : CoresApp.linha,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}
