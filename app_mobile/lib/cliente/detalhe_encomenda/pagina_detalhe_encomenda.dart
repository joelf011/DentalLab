import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/detalhe_encomenda/widget_aba_historico.dart';
import 'package:app_mobile/cliente/detalhe_encomenda/widget_aba_mensagens.dart';
import 'package:app_mobile/cliente/detalhe_encomenda/widget_aba_progresso.dart';
import 'package:app_mobile/cliente/detalhe_encomenda/widget_aba_resumo.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_natureza.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_prazo.dart';

// Detalhe de uma encomenda da clínica, com 4 abas:
// Resumo · Progresso · Informação (mensagens) · Histórico.
class PaginaDetalheEncomenda extends StatefulWidget {
  const PaginaDetalheEncomenda({super.key, required this.encomenda});

  final Encomenda encomenda;

  @override
  State<PaginaDetalheEncomenda> createState() => _PaginaDetalheEncomendaState();
}

class _PaginaDetalheEncomendaState extends State<PaginaDetalheEncomenda> {
  void _voltar() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final encomenda = widget.encomenda;
    final prazo = encomenda.prazo;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar às encomendas',
            onPressed: _voltar,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                encomenda.referencia,
                style: const TextStyle(
                  fontSize: 12,
                  color: CoresApp.textoSuave,
                ),
              ),
              Text(encomenda.tipo, style: const TextStyle(fontSize: 16)),
              if (encomenda.descricao != null && encomenda.descricao!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  encomenda.descricao!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CoresApp.textoSuave,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (prazo != null)
              EtiquetaPrazo(
                prazo: prazo,
                concluido: encomenda.estado == 'concluido',
              ),
            const SizedBox(width: 16),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: CoresApp.douradoEscuro,
            indicatorColor: CoresApp.dourado,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Progresso'),
              Tab(text: 'Informação'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  EtiquetaEstado(estado: encomenda.estado, paraClinica: true),
                  const SizedBox(width: 8),
                  EtiquetaNatureza(natureza: encomenda.natureza),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  AbaResumo(encomenda: encomenda),
                  AbaProgresso(encomenda: encomenda),
                  AbaMensagens(encomenda: encomenda),
                  AbaHistorico(encomenda: encomenda),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
