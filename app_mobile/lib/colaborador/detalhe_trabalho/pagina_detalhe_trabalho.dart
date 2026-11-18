import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_concluir_etapa.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_fotografia.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_nota.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_standby.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_prazo.dart';

class PaginaDetalheTrabalho extends StatefulWidget {
  const PaginaDetalheTrabalho({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<PaginaDetalheTrabalho> createState() => _PaginaDetalheTrabalhoState();
}

class _PaginaDetalheTrabalhoState extends State<PaginaDetalheTrabalho> {
  final _servidor = const ServidorColaborador();
  bool _aCarregar = false;

  Future<void> _assumirEtapa() async {
    setState(() => _aCarregar = true);
    await _servidor.assumirEtapa(widget.trabalho.id);
    if (!mounted) return;
    setState(() => _aCarregar = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etapa atual iniciada com sucesso.')),
    );
  }

  void _adicionarNota() => mostrarJanelaNota(context, widget.trabalho);
  void _adicionarFotografia() => mostrarJanelaFotografia(context, widget.trabalho);
  void _colocarEmStandby() => mostrarJanelaStandby(context, widget.trabalho);
  void _concluirEtapa() => mostrarJanelaConcluirEtapa(context, widget.trabalho);

  @override
  Widget build(BuildContext context) {
    final trabalho = widget.trabalho;
    final colaboradorId = Sessao.atual?.id ?? '';
    final estaEmExecucao = trabalho.estaEmExecucaoPor(colaboradorId);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Fundo ligeiramente off-white tipico de UI moderna
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trabalho.referencia,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CoresApp.textoSuave,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              trabalho.descricao,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: EtiquetaPrazo(
                prazo: trabalho.prazo,
                concluido: trabalho.estado == 'concluido',
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho de Estado e Clínica
          Row(
            children: [
              EtiquetaEstado(estado: trabalho.estado, paraClinica: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trabalho.clinica,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CoresApp.textoSuave,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cartão "Etapa Ativa" com destaque visual refinado
          if (trabalho.etapaAtiva != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(color: CoresApp.dourado, width: 1.5),
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: CoresApp.dourado.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ETAPA ATIVA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CoresApp.douradoEscuro,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CoresApp.douradoClaro.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Em curso',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: CoresApp.douradoEscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trabalho.etapaAtiva!.nome,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: CoresApp.textoSuave),
                      const SizedBox(width: 4),
                      Text(
                        trabalho.etapaAtiva!.iniciadaEm != null
                            ? 'Iniciada em ${trabalho.etapaAtiva!.iniciadaEm.toString().substring(11, 16)}'
                            : 'Iniciada recentemente',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CoresApp.textoSuave,
                        ),
                      ),
                      if (trabalho.etapaAtiva!.colaboradorNome != null) ...[
                        const Text(' • ', style: TextStyle(color: CoresApp.textoSuave)),
                        Text(
                          trabalho.etapaAtiva!.colaboradorNome!.split(' ').first,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Secção "Consultar etapas do processo" (ExpansionTile com aspeto de Cartão Limpo)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            margin: EdgeInsets.zero,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text(
                'Consultar etapas do processo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              children: [
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trabalho.etapas.length,
                  itemBuilder: (context, index) {
                    final etapa = trabalho.etapas[index];
                    final primeiroNomeColaborador = etapa.colaboradorNome != null
                        ? etapa.colaboradorNome!.split(' ').first
                        : 'Por atribuir';

                    return ListTile(
                      dense: true,
                      leading: _obterIconeEstado(etapa.estado),
                      title: Text(
                        etapa.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        primeiroNomeColaborador,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CoresApp.textoSuave,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Secção de Ações
          const Text(
            'AÇÕES DO COLABORADOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: CoresApp.textoSuave,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          if (trabalho.estaDisponivel)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _aCarregar ? null : _assumirEtapa,
                style: FilledButton.styleFrom(
                  backgroundColor: CoresApp.douradoEscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Assumir Etapa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (estaEmExecucao) ...[
            // Botões secundários: Nota, Foto, Standby
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _adicionarNota,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.note_add, size: 16),
                    label: const Text('Nota', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _adicionarFotografia,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Foto', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _colocarEmStandby,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.pause_circle_outline, size: 16),
                    label: const Text('Standby', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _concluirEtapa,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Concluir Etapa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _obterIconeEstado(String estado) {
    switch (estado) {
      case 'concluido':
      case 'concluida':
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case 'em_execucao':
      case 'execucao':
        return const Icon(Icons.access_time_filled, color: CoresApp.dourado, size: 20);
      default:
        return const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20);
    }
  }
}