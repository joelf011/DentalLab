import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_concluir_etapa.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_standby.dart';
import 'package:app_mobile/colaborador/trabalhos/widget_cartao_trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// Separador "Os Meus": trabalhos atribuídos a quem tem sessão, por concluir.
// Os botões dos cartões abrem as janelas do detalhe do trabalho:
//   mostrarJanelaConcluirEtapa(context, trabalho) -> "Concluir Etapa"
//   mostrarJanelaStandby(context, trabalho)       -> "Standby"
class PaginaOsMeus extends StatefulWidget {
  const PaginaOsMeus({super.key});

  @override
  State<PaginaOsMeus> createState() => _PaginaOsMeusState();
}

class _PaginaOsMeusState extends State<PaginaOsMeus> {
  final _servidor = const ServidorColaborador();
  late Future<List<Trabalho>> _futuro;
  final Set<String> _ocupados = {};

  void _recarregar() {
    if (!mounted) return;
    setState(() => _futuro = _servidor.obterTrabalhos());
  }

  VarianteCartaoTrabalho _variante(Trabalho trabalho) {
    if (trabalho.estaEmExecucaoPor(Sessao.atual!.id)) {
      return VarianteCartaoTrabalho.emProcessamento;
    }
    if (trabalho.estaDisponivel) return VarianteCartaoTrabalho.emEspera;
    return VarianteCartaoTrabalho.normal;
  }

  Future<void> _iniciarEtapa(Trabalho trabalho) async {
    if (_ocupados.contains(trabalho.id)) return;
    setState(() => _ocupados.add(trabalho.id));
    try {
      await _servidor.assumirEtapa(trabalho.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Etapa iniciada')));
      _recarregar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível iniciar a etapa.')),
      );
    } finally {
      if (mounted) setState(() => _ocupados.remove(trabalho.id));
    }
  }

  Future<void> _concluirEtapa(Trabalho trabalho) async {
    await mostrarJanelaConcluirEtapa(context, trabalho);
    _recarregar();
  }

  Future<void> _colocarEmStandby(Trabalho trabalho) async {
    await mostrarJanelaStandby(context, trabalho);
    _recarregar();
  }

  @override
  void initState() {
    super.initState();
    _futuro = _servidor.obterTrabalhos();
  }

  void _abrirTrabalho(Trabalho trabalho) {
    context.push(Rotas.detalheTrabalho, extra: trabalho);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Trabalho>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final eu = Sessao.atual!.id;
          final meus = snapshot.data!
              .where(
                (trabalho) =>
                    trabalho.responsavelId == eu &&
                    trabalho.estado != 'concluido',
              )
              .toList();
          return _lista(meus);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _lista(List<Trabalho> trabalhos) {
    if (trabalhos.isEmpty) return const EstadoVazio(mensagem: 'Sem trabalhos');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final trabalho in trabalhos)
          CartaoTrabalho(
            key: ValueKey(trabalho.id),
            trabalho: trabalho,
            variante: _variante(trabalho),
            aoAbrir: _abrirTrabalho,
            aoIniciar: _iniciarEtapa,
            aoConcluir: _concluirEtapa,
            aoStandby: _colocarEmStandby,
            ocupado: _ocupados.contains(trabalho.id),
          ),
      ],
    );
  }
}
