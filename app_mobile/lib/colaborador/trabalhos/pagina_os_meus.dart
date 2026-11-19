import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
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
          CartaoTrabalho(trabalho: trabalho, aoAbrir: _abrirTrabalho),
      ],
    );
  }
}
