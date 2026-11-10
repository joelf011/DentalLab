import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/encomenda_nova.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

import 'rascunho_trabalho.dart';
import 'widget_encomenda_enviada.dart';
import 'widget_formulario_trabalho.dart';
import 'widget_passo_encomenda.dart';

class PaginaNovaEncomenda extends StatefulWidget {
  const PaginaNovaEncomenda({super.key});

  @override
  State<PaginaNovaEncomenda> createState() => _PaginaNovaEncomendaState();
}

class _PaginaNovaEncomendaState extends State<PaginaNovaEncomenda> {
  final _servidor = const ServidorCliente();
  final _chaveFormulario = GlobalKey<FormState>();
  late TextEditingController _medico;
  late TextEditingController _identificacao;
  late TextEditingController _idade;
  late Future<List<TipoTrabalho>> _futuroTipos;
  final List<RascunhoTrabalho> _trabalhos = [];
  String? _sexo;
  int _passo = 1;
  bool _aEnviar = false;
  String? _referencia;
  EncomendaNova? _encomendaEnviada;

  @override
  void initState() {
    super.initState();
    _medico = TextEditingController();
    _identificacao = TextEditingController();
    _idade = TextEditingController();
    _futuroTipos = _servidor.obterTiposTrabalho();
    _trabalhos.add(RascunhoTrabalho());
  }

  @override
  void dispose() {
    _medico.dispose();
    _identificacao.dispose();
    _idade.dispose();
    super.dispose();
  }

  void _cancelar() => context.pop(false);
  void _verEncomendas() => context.pop(true);

  void _voltar() {
    if (_passo == 1) {
      _cancelar();
    } else {
      setState(() => _passo = 1);
    }
  }

  void _aoVoltar(bool saiu, bool? resultado) {
    if (!saiu && !_aEnviar) _voltar();
  }

  void _continuar() {
    if (!_chaveFormulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _passo = 2);
  }

  void _mudarSexo(String? sexo) => setState(() => _sexo = sexo);
  void _atualizarTrabalhos() => setState(() {});

  void _adicionarTrabalho() {
    setState(() => _trabalhos.add(RascunhoTrabalho()));
  }

  void _removerTrabalho(RascunhoTrabalho trabalho) {
    setState(() {
      _trabalhos.remove(trabalho);
      if (_trabalhos.isEmpty) _trabalhos.add(RascunhoTrabalho());
    });
  }

  void _repetirCarregamento() {
    setState(() => _futuroTipos = _servidor.obterTiposTrabalho());
  }

  Future<void> _enviar() async {
    if (_aEnviar || _trabalhos.any((trabalho) => trabalho.tipo == null)) return;
    final clinica = Sessao.atual?.clinica;
    if (clinica == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicie sessão com uma conta de clínica.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final encomenda = EncomendaNova(
      clinicaId: clinica.id,
      medico: _medico.text.trim(),
      paciente: _identificacao.text.trim(),
      idade: int.tryParse(_idade.text.trim()),
      sexo: _sexo,
      trabalhos: _trabalhos
          .map((trabalho) => trabalho.paraTrabalhoNovo())
          .toList(),
    );
    setState(() => _aEnviar = true);
    try {
      final referencia = await _servidor.enviarEncomenda(encomenda);
      if (!mounted) return;
      setState(() {
        _referencia = referencia;
        _encomendaEnviada = encomenda;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível enviar a encomenda. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _aEnviar = false);
    }
  }

  void _novaEncomenda() {
    _medico.clear();
    _identificacao.clear();
    _idade.clear();
    setState(() {
      _sexo = null;
      _passo = 1;
      _referencia = null;
      _encomendaEnviada = null;
      _trabalhos
        ..clear()
        ..add(RascunhoTrabalho());
    });
  }

  Widget _passoTrabalhos() {
    return FutureBuilder<List<TipoTrabalho>>(
      future: _futuroTipos,
      builder: (context, snapshot) {
        if (snapshot.hasError || (snapshot.hasData && snapshot.data!.isEmpty)) {
          return Column(
            children: [
              const Text('Não foi possível carregar os tipos de trabalho.'),
              TextButton(
                onPressed: _repetirCarregamento,
                child: const Text('Tentar novamente'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (indice, trabalho) in _trabalhos.indexed)
              FormularioTrabalho(
                key: ObjectKey(trabalho),
                numero: indice + 1,
                trabalho: trabalho,
                tipos: snapshot.data!,
                aoMudar: _atualizarTrabalhos,
                aoRemover: _removerTrabalho,
              ),
            OutlinedButton.icon(
              onPressed: _adicionarTrabalho,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar trabalho'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final enviada = _referencia != null;
    final podeEnviar =
        !_aEnviar && _trabalhos.every((trabalho) => trabalho.tipo != null);
    return PopScope<bool>(
      canPop: !_aEnviar && (_passo == 1 || enviada),
      onPopInvokedWithResult: _aoVoltar,
      child: Scaffold(
        appBar: enviada
            ? null
            : AppBar(
                leading: IconButton(
                  tooltip: 'Voltar',
                  onPressed: _aEnviar ? null : _voltar,
                  icon: const Icon(Icons.arrow_back),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASSO $_passo DE 2',
                      style: const TextStyle(
                        fontSize: 10,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                    Text(
                      _passo == 1 ? 'Encomenda' : 'Detalhes do Trabalho',
                      style: const TextStyle(fontFamily: 'serif', fontSize: 18),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Cancelar',
                    onPressed: _aEnviar ? null : _cancelar,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
        body: SafeArea(
          child: enviada
              ? EncomendaEnviada(
                  referencia: _referencia!,
                  encomenda: _encomendaEnviada!,
                  aoVerEncomendas: _verEncomendas,
                  aoNovaEncomenda: _novaEncomenda,
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        spacing: 6,
                        children: [
                          for (var indice = 1; indice <= 2; indice++)
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: indice <= _passo
                                      ? CoresApp.dourado
                                      : CoresApp.linha,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: _aEnviar,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: _passo == 1
                              ? PassoEncomenda(
                                  chaveFormulario: _chaveFormulario,
                                  medico: _medico,
                                  identificacao: _identificacao,
                                  idade: _idade,
                                  sexo: _sexo,
                                  aoMudarSexo: _mudarSexo,
                                )
                              : _passoTrabalhos(),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      color: CoresApp.superficie,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: FilledButton(
                        onPressed: _passo == 1
                            ? _continuar
                            : (podeEnviar ? _enviar : null),
                        child: _aEnviar
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _passo == 1
                                    ? 'Continuar'
                                    : 'Enviar Encomenda · ${_trabalhos.length} ${_trabalhos.length == 1 ? 'trabalho' : 'trabalhos'}',
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
