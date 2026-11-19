import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_concluir_etapa.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_fotografia.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_nota.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/janela_standby.dart';
import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_prazo.dart';

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
  final _servidor = const ServidorColaborador();
  bool _aAssumir = false;

  void _voltar() {
    context.pop();
  }

  // Assume a etapa atual (fica com o colaborador e começa agora).
  Future<void> _assumirEtapa() async {
    final etapa = widget.trabalho.etapaAtual;
    if (etapa == null) return;
    setState(() {
      _aAssumir = true;
    });
    await _servidor.assumirEtapa(etapa.id);
    if (!mounted) return;
    setState(() {
      _aAssumir = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Etapa atual iniciada')));
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
    final etapa = trabalho.etapaAtual;
    final prazo = trabalho.prazoEntrega;
    final estaEmExecucao = trabalho.estaEmExecucaoPor(Sessao.atual!.id);

    return Scaffold(
      backgroundColor: CoresApp.fundo,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CoresApp.superficie,
        foregroundColor: CoresApp.textoForte,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: _voltar,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ordem n.º ${trabalho.ordemTrabalhoId}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CoresApp.textoSuave,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              trabalho.tipoTrabalho,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: CoresApp.textoForte,
              ),
            ),
          ],
        ),
        actions: [
          if (prazo != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: EtiquetaPrazo(
                  prazo: prazo,
                  estado: trabalho.estadoOrdem,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado da ordem e clínica
          Row(
            children: [
              EtiquetaEstado(estado: trabalho.estadoOrdem),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trabalho.cliente,
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

          // Cartão "Etapa ativa"
          if (etapa != null) ...[
            _CartaoEtapaAtiva(etapa: etapa),
            const SizedBox(height: 20),
          ],

          // Secção que abre e fecha com todas as etapas
          Card(
            elevation: 0,
            color: CoresApp.superficie,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CoresApp.linha),
            ),
            margin: EdgeInsets.zero,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text(
                'Consultar etapas do processo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.textoForte,
                ),
              ),
              children: [
                const Divider(height: 1, thickness: 1, color: CoresApp.linha),
                for (final etapaDoProcesso in trabalho.etapas)
                  ListTile(
                    dense: true,
                    leading: _iconeDaEtapa(etapaDoProcesso),
                    title: Text(
                      etapaDoProcesso.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      _primeiroNome(etapaDoProcesso.responsavel),
                      style: const TextStyle(
                        fontSize: 11,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Ações
          const Text(
            'AÇÕES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: CoresApp.textoSuave,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (trabalho.estaDisponivel)
            FilledButton(
              onPressed: _aAssumir ? null : _assumirEtapa,
              style: FilledButton.styleFrom(
                backgroundColor: CoresApp.dourado,
                foregroundColor: CoresApp.textoForte,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _aAssumir ? 'A assumir...' : 'Assumir Etapa',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (estaEmExecucao) ...[
            const Text(
              'Notas, fotografias e standby',
              style: TextStyle(fontSize: 13, color: CoresApp.texto),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BotaoAcao(
                    texto: 'Nota',
                    icone: Icons.note_add,
                    aoPressionar: _adicionarNota,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BotaoAcao(
                    texto: 'Foto',
                    icone: Icons.camera_alt,
                    aoPressionar: _adicionarFotografia,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BotaoAcao(
                    texto: 'Standby',
                    icone: Icons.pause_circle_outline,
                    aoPressionar: _colocarEmStandby,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _concluirEtapa,
              style: FilledButton.styleFrom(
                backgroundColor: CoresApp.sucesso,
                foregroundColor: CoresApp.superficie,
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
          ] else
            const Text(
              'A etapa atual não está atribuída a si.',
              style: TextStyle(fontSize: 13, color: CoresApp.textoSuave),
            ),
        ],
      ),
    );
  }

  // ✓ concluída, ◷ em curso, ○ por iniciar.
  Widget _iconeDaEtapa(EtapaTrabalho etapa) {
    return switch (etapa.estado) {
      'Concluída' => const Icon(
        Icons.check_circle,
        color: CoresApp.sucesso,
        size: 20,
      ),
      'Em curso' => const Icon(
        Icons.access_time_filled,
        color: CoresApp.dourado,
        size: 20,
      ),
      _ => const Icon(
        Icons.radio_button_unchecked,
        color: CoresApp.textoSuave,
        size: 20,
      ),
    };
  }
}

// Primeiro nome do colaborador, ou "Por atribuir".
String _primeiroNome(String? nome) {
  if (nome == null || nome.isEmpty) return 'Por atribuir';
  return nome.split(' ').first;
}

// Cartão com borda dourada: nome da etapa atual e quando começou.
class _CartaoEtapaAtiva extends StatelessWidget {
  const _CartaoEtapaAtiva({required this.etapa});

  final EtapaTrabalho etapa;

  @override
  Widget build(BuildContext context) {
    final inicio = etapa.dataInicio;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: CoresApp.dourado, width: 1.5),
        borderRadius: BorderRadius.circular(14),
        color: CoresApp.superficie,
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
                  color: CoresApp.douradoClaro,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  etapa.estado,
                  style: const TextStyle(
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
            etapa.nome,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: CoresApp.textoForte,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 14,
                color: CoresApp.textoSuave,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  inicio != null
                      ? 'Iniciada em ${dataHora(inicio)}'
                      : 'Ainda por iniciar',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CoresApp.textoSuave,
                  ),
                ),
              ),
              if (etapa.responsavel != null) ...[
                const Text(' • ', style: TextStyle(color: CoresApp.textoSuave)),
                Text(
                  _primeiroNome(etapa.responsavel),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CoresApp.texto,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Botão pequeno com ícone (Nota, Foto, Standby).
class _BotaoAcao extends StatelessWidget {
  const _BotaoAcao({
    required this.texto,
    required this.icone,
    required this.aoPressionar,
  });

  final String texto;
  final IconData icone;
  final VoidCallback aoPressionar;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: aoPressionar,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icone, size: 16),
      label: Text(texto, style: const TextStyle(fontSize: 12)),
    );
  }
}
