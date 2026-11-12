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

// Ecrã de execução de um trabalho (colaborador): etapa ativa, etapas do
// processo e ações (Assumir Etapa, nota, fotografia, standby, Concluir Etapa).
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
      const SnackBar(content: Text('Etapa atual iniciada.')),
    );
  }

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
    final colaboradorId = Sessao.atual?.id ?? '';
    final estaEmExecucao = trabalho.estaEmExecucaoPor(colaboradorId);

    return Scaffold(
      appBar: AppBar(
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
              style: const TextStyle(fontSize: 12, color: CoresApp.textoSuave),
            ),
            Text(trabalho.descricao, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          EtiquetaPrazo(
            prazo: trabalho.prazo,
            concluido: trabalho.estado == 'concluido',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado e Clínica
          Row(
            children: [
              EtiquetaEstado(estado: trabalho.estado, paraClinica: false),
              const SizedBox(width: 8),
              Text(
                trabalho.clinica,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CoresApp.textoSuave,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cartão "Etapa Ativa" com borda dourada
          if (trabalho.etapaAtiva != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: CoresApp.dourado, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: CoresApp.douradoClaro.withValues(alpha: 0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ETAPA ATIVA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.douradoEscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trabalho.etapaAtiva!.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trabalho.etapaAtiva!.iniciadaEm != null
                        ? 'Iniciada em ${trabalho.etapaAtiva!.iniciadaEm.toString().substring(0, 16)}'
                        : 'Em execução',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoresApp.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Secção "Consultar etapas do processo" (ExpansionTile)
          Card(
            margin: EdgeInsets.zero,
            child: ExpansionTile(
              title: const Text(
                'Consultar etapas do processo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              children: [
                for (final etapa in trabalho.etapas)
                  ListTile(
                    leading: _obrigarIconeEstado(etapa.estado),
                    title: Text(etapa.nome),
                    subtitle: etapa.colaboradorNome != null
                        ? Text('Colaborador: ${etapa.colaboradorNome!.split(' ').first}')
                        : const Text('Por atribuir'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Secção de Ações
          const Text(
            'AÇÕES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CoresApp.textoSuave,
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Assumir Etapa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (estaEmExecucao) ...[
            // Notas, fotografias e standby
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _adicionarNota,
                    icon: const Icon(Icons.note_add, size: 18),
                    label: const Text('Nota'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _adicionarFotografia,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Foto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _colocarEmStandby,
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label: const Text('Standby'),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _obrigarIconeEstado(String estado) {
    switch (estado) {
      case 'concluido':
      case 'concluida':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'em_execucao':
      case 'execucao':
        return const Icon(Icons.access_time_filled, color: CoresApp.dourado);
      default:
        return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
  }
}