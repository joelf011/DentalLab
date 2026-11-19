import 'package:flutter/material.dart';

import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_concluir_etapa.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_fotografia.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_nota.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_standby.dart';
import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// Ecrã de execução de um trabalho (colaborador): etapa ativa, etapas do
// processo e ações (Assumir Etapa, nota, fotografia, standby, Concluir Etapa).
// Rota: Rotas.detalheTrabalho (extra: Trabalho).
// Quem tem sessão: Sessao.atual!.id (para saber se pode assumir ou concluir).
class PaginaDetalheTrabalho extends StatefulWidget {
  const PaginaDetalheTrabalho({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<PaginaDetalheTrabalho> createState() => _PaginaDetalheTrabalhoState();
}

class _PaginaDetalheTrabalhoState extends State<PaginaDetalheTrabalho> {
  void _adicionarNota() {
    mostrarJanelaNota(context, widget.trabalho);
  }

  void _adicionarFotografia() {
    mostrarJanelaFotografia(context, widget.trabalho);
  }

  void _colocarEmStandby() {
    mostrarJanelaStandby(context, widget.trabalho);
  }

  void _concluirEtapa() {
    mostrarJanelaConcluirEtapa(context, widget.trabalho);
  }

  @override
  Widget build(BuildContext context) {
    final trabalho = widget.trabalho;
    return Scaffold(
      appBar: AppBar(title: Text(trabalho.referencia)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          EmConstrucao(
            titulo: trabalho.descricao,
            descricao: 'Etapa atual: ${trabalho.etapaAtual}',
          ),
          // Provisório: botões para testar as 4 janelas.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _adicionarNota,
                child: const Text('Nota'),
              ),
              OutlinedButton(
                onPressed: _adicionarFotografia,
                child: const Text('Fotografia'),
              ),
              OutlinedButton(
                onPressed: _colocarEmStandby,
                child: const Text('Standby'),
              ),
              FilledButton(
                onPressed: _concluirEtapa,
                child: const Text('Concluir Etapa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
