import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';
import 'package:app_mobile/cliente/inicio/widget_contador.dart';
import 'package:app_mobile/colaborador/trabalhos/widget_cartao_trabalho.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';

// Separador "Início" do colaborador: "Olá, nome", contadores (Ativos /
// Em execução / Urgentes) e as 3 prioridades.
//   Tocar em "Ativos" ou "Em execução" -> widget.aoVerOsMeus()
//   Tocar em "Urgentes" ou "Ver todos" -> context.push(Rotas.prazos)
class PaginaInicioColaborador extends StatefulWidget {
  const PaginaInicioColaborador({super.key, required this.aoVerOsMeus});

  final VoidCallback aoVerOsMeus;

  @override
  State<PaginaInicioColaborador> createState() =>
      _PaginaInicioColaboradorState();
}

class _PaginaInicioColaboradorState extends State<PaginaInicioColaborador> {
  final _servidor = const ServidorColaborador();
  late Future<List<Trabalho>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servidor.obterTrabalhos();
  }

  void _verPrazos() {
    context.push(Rotas.prazos);
  }

  void _abrirTrabalho(Trabalho trabalho) {
    context.push(Rotas.detalheTrabalho, extra: trabalho);
  }

  // Primeiro os que estão em processamento, depois pelo prazo mais próximo
  // (os que não têm prazo ficam no fim).
  int _compararPrioridade(Trabalho primeiro, Trabalho segundo) {
    final prioridadePrimeiro = primeiro.estadoOrdem == 'Em processamento'
        ? 0
        : 1;
    final prioridadeSegundo = segundo.estadoOrdem == 'Em processamento' ? 0 : 1;
    final ordem = prioridadePrimeiro.compareTo(prioridadeSegundo);
    if (ordem != 0) return ordem;
    final prazoPrimeiro = primeiro.prazoEntrega;
    final prazoSegundo = segundo.prazoEntrega;
    if (prazoPrimeiro == null && prazoSegundo == null) return 0;
    if (prazoPrimeiro == null) return 1;
    if (prazoSegundo == null) return -1;
    return prazoPrimeiro.compareTo(prazoSegundo);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Trabalho>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _conteudo(snapshot.data!);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _conteudo(List<Trabalho> trabalhos) {
    final eu = Sessao.atual!.id;

    final meus = trabalhos.where((trabalho) => trabalho.eDe(eu)).toList();
    final ativos = meus.length;
    meus.sort(_compararPrioridade);
    final prioridades = meus.take(3).toList();

    final emExecucao = trabalhos
        .where((trabalho) => trabalho.estaEmExecucaoPor(eu))
        .length;

    final urgentes = trabalhos.where((trabalho) => trabalho.eUrgente).length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Olá, ${Sessao.atual!.nome}',
          style: const TextStyle(
            fontSize: 22,
            color: CoresApp.textoForte,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Sessao.atual!.cargo,
          style: const TextStyle(fontSize: 13, color: CoresApp.textoSuave),
        ),
        const SizedBox(height: 20),
        Contador(
          texto: 'Ativos',
          valor: ativos,
          cor: CoresApp.douradoEscuro,
          fundo: CoresApp.douradoClaro,
          aoTocar: widget.aoVerOsMeus,
        ),
        Contador(
          texto: 'Em execução',
          valor: emExecucao,
          cor: CoresApp.info,
          corValor: CoresApp.info,
          fundo: CoresApp.infoClaro,
          aoTocar: widget.aoVerOsMeus,
        ),
        Contador(
          texto: 'Urgentes',
          valor: urgentes,
          cor: CoresApp.erro,
          corValor: CoresApp.erro,
          fundo: CoresApp.avisoClaro,
          aoTocar: _verPrazos,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Prioridades e Urgências',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CoresApp.textoForte,
                ),
              ),
            ),
            TextButton(
              onPressed: _verPrazos,
              style: TextButton.styleFrom(
                foregroundColor: CoresApp.douradoEscuro,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Ver todos →'),
            ),
          ],
        ),
        if (prioridades.isEmpty)
          const EstadoVazio(mensagem: 'Sem trabalhos atribuídos.')
        else
          for (final trabalho in prioridades)
            CartaoTrabalho(
              key: ValueKey(trabalho.id),
              trabalho: trabalho,
              aoAbrir: _abrirTrabalho,
            ),
      ],
    );
  }
}
