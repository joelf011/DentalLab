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

  int _compararPrioridade(Trabalho primeiro, Trabalho segundo) {
    final prioridadePrimeiro = primeiro.estado == 'em_producao' ? 0 : 1;
    final prioridadeSegundo = segundo.estado == 'em_producao' ? 0 : 1;
    final ordem = prioridadePrimeiro.compareTo(prioridadeSegundo);
    if (ordem != 0) return ordem;
    return primeiro.prazo.compareTo(segundo.prazo);
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

    final meus = trabalhos
        .where(
          (trabalho) =>
              trabalho.responsavelId == eu && trabalho.estado != 'concluido',
        )
        .toList();
    final ativos = meus.length;
    meus.sort(_compararPrioridade);
    final prioridades = meus.take(3).toList();

    final emExecucao = trabalhos
        .where((trabalho) => trabalho.estaEmExecucaoPor(eu))
        .length;

    final urgentes = trabalhos.where((trabalho) => trabalho.eUrgente).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Olá, ${Sessao.atual!.nome}',
          style: const TextStyle(fontSize: 20, color: CoresApp.textoForte),
        ),
        const SizedBox(height: 4),
        Text(
          Sessao.atual!.cargo,
          style: const TextStyle(fontSize: 14, color: CoresApp.textoSuave),
        ),
        const SizedBox(height: 16),
        Contador(
          margem: EdgeInsets.zero,
          espacamento: const EdgeInsets.all(16),
          alturaMinima: 0,
          estiloTexto: const TextStyle(fontSize: 14),
          estiloValor: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          texto: 'Ativos',
          valor: ativos,
          cor: CoresApp.douradoEscuro,
          corValor: CoresApp.textoForte,
          fundo: CoresApp.douradoClaro,
          aoTocar: widget.aoVerOsMeus,
        ),
        const SizedBox(height: 10),
        Contador(
          margem: EdgeInsets.zero,
          espacamento: const EdgeInsets.all(16),
          alturaMinima: 0,
          estiloTexto: const TextStyle(fontSize: 14),
          estiloValor: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          texto: 'Em execução',
          valor: emExecucao,
          cor: CoresApp.info,
          corValor: CoresApp.info,
          fundo: CoresApp.infoClaro,
          aoTocar: widget.aoVerOsMeus,
        ),
        const SizedBox(height: 10),
        Contador(
          margem: EdgeInsets.zero,
          espacamento: const EdgeInsets.all(16),
          alturaMinima: 0,
          estiloTexto: const TextStyle(fontSize: 14),
          estiloValor: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          texto: 'Urgentes',
          valor: urgentes,
          cor: CoresApp.erro,
          corValor: CoresApp.erro,
          fundo: CoresApp.avisoClaro,
          aoTocar: _verPrazos,
        ),
        const SizedBox(height: 24),
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
                foregroundColor: CoresApp.textoSuave,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Ver todos →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
