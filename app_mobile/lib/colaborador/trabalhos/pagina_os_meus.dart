import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_concluir_etapa.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_standby.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_prazo.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

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

  void _colocarEmStandby(Trabalho trabalho) => mostrarJanelaStandby(context, trabalho);
  void _concluirEtapa(Trabalho trabalho) => mostrarJanelaConcluirEtapa(context, trabalho);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Trabalho>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final eu = Sessao.atual?.id ?? '';
          final meus = snapshot.data!
              .where(
                (trabalho) =>
                    trabalho.responsavelId == eu &&
                    trabalho.estado != 'concluido',
              )
              .toList();
          return _lista(meus, eu);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _lista(List<Trabalho> trabalhos, String colaboradorId) {
    if (trabalhos.isEmpty) return const EstadoVazio(mensagem: 'Sem trabalhos');
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Título no canto superior esquerdo idêntico ao Figma
        const Text(
          'Trabalhos Atribuídos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        for (final trabalho in trabalhos) ...[
          _construirCartaoTrabalho(trabalho, colaboradorId),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _construirCartaoTrabalho(Trabalho trabalho, String colaboradorId) {
    final estaEmExecucao = trabalho.estaEmExecucaoPor(colaboradorId);

    return InkWell(
      onTap: () => _abrirTrabalho(trabalho),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: estaEmExecucao ? Colors.green.shade700 : Colors.grey.shade200,
            width: estaEmExecucao ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: estaEmExecucao ? Colors.green.shade700 : Colors.transparent,
                  width: 6,
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    EtiquetaEstado(estado: trabalho.estado, paraClinica: false),
                    EtiquetaPrazo(
                      prazo: trabalho.prazo,
                      concluido: trabalho.estado == 'concluido',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  trabalho.referencia,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CoresApp.textoSuave,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trabalho.descricao,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  trabalho.clinica,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CoresApp.textoSuave,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ver dados do trabalho',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Icon(Icons.add, size: 18, color: Colors.black87),
                  ],
                ),
                if (estaEmExecucao) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _colocarEmStandby(trabalho),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Standby'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _concluirEtapa(trabalho),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Concluir Etapa'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}