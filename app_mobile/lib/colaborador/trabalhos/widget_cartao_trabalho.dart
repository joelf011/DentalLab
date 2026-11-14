import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_natureza.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_prazo.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';

enum VarianteCartaoTrabalho { normal, emProcessamento, emEspera }

class CartaoTrabalho extends StatelessWidget {
  const CartaoTrabalho({
    super.key,
    required this.trabalho,
    required this.aoAbrir,
    this.variante = VarianteCartaoTrabalho.normal,
    this.aoIniciar,
    this.aoConcluir,
    this.aoStandby,
    this.ocupado = false,
  });

  final VarianteCartaoTrabalho variante;
  final Trabalho trabalho;
  final ValueChanged<Trabalho> aoAbrir;
  final ValueChanged<Trabalho>? aoIniciar;
  final ValueChanged<Trabalho>? aoConcluir;
  final ValueChanged<Trabalho>? aoStandby;
  final bool ocupado;

  void _iniciar() => aoIniciar?.call(trabalho);
  void _concluir() => aoConcluir?.call(trabalho);
  void _standby() => aoStandby?.call(trabalho);

  void _abrir() {
    aoAbrir(trabalho);
  }

  @override
  Widget build(BuildContext context) {
    final emProcessamento = variante == VarianteCartaoTrabalho.emProcessamento;
    final normal = variante == VarianteCartaoTrabalho.normal;
    return Card(
      color: CoresApp.superficie,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: emProcessamento ? CoresApp.sucesso : CoresApp.linha,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: normal ? _abrir : null,
        child: Container(
          decoration: BoxDecoration(
            border: emProcessamento
                ? const Border(
                    left: BorderSide(color: CoresApp.sucesso, width: 4),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (emProcessamento) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CoresApp.sucessoClaro,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: CoresApp.sucesso,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'EM PROCESSAMENTO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: CoresApp.sucesso,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            trabalho.referencia,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CoresApp.textoSuave,
                            ),
                          ),
                          if (variante == VarianteCartaoTrabalho.emEspera) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CoresApp.fundo,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '● EM ESPERA',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: CoresApp.textoSuave,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            trabalho.descricao,
                            maxLines: normal ? 1 : null,
                            overflow: normal ? TextOverflow.ellipsis : null,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: CoresApp.textoForte,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trabalho.clinica,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CoresApp.textoForte,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    EtiquetaPrazo(
                      prazo: trabalho.prazo,
                      concluido: trabalho.estado == "concluido",
                    ),
                  ],
                ),
                if (normal) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: CoresApp.linha,
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      EtiquetaEstado(estado: trabalho.estado),
                      const Text(
                        'Abrir trabalho ›',
                        style: TextStyle(
                          fontSize: 14,
                          color: CoresApp.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    key: PageStorageKey(
                      'dados-${trabalho.id}-${variante.name}',
                    ),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    title: const Text(
                      'Ver dados do trabalho',
                      style: TextStyle(
                        fontSize: 13,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                              EtiquetaNatureza(natureza: trabalho.natureza),
                            Text(
                              trabalho.etapaAtual,
                              style: TextStyle(
                                color: emProcessamento
                                    ? CoresApp.sucesso
                                    : CoresApp.textoSuave,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (emProcessamento)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: ocupado || aoStandby == null
                                ? null
                                : _standby,
                            child: const Text('Standby'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: ocupado || aoConcluir == null
                                ? null
                                : _concluir,
                            style: FilledButton.styleFrom(
                              backgroundColor: CoresApp.sucesso,
                              foregroundColor: CoresApp.superficie,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              '✓ Concluir Etapa',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    FilledButton.icon(
                      onPressed: ocupado || aoIniciar == null ? null : _iniciar,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(ocupado ? 'A iniciar…' : 'Iniciar Etapa'),
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
