import 'package:flutter/material.dart';
import 'package:app_mobile/colaborador/dados/colaborador.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

void mostrarJanelaConcluirEtapa(BuildContext context, Trabalho trabalho) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _JanelaConcluirEtapaConteudo(trabalho: trabalho),
  );
}

class _JanelaConcluirEtapaConteudo extends StatefulWidget {
  const _JanelaConcluirEtapaConteudo({required this.trabalho});

  final Trabalho trabalho;

  @override
  State<_JanelaConcluirEtapaConteudo> createState() => _JanelaConcluirEtapaConteudoState();
}

class _JanelaConcluirEtapaConteudoState extends State<_JanelaConcluirEtapaConteudo> {
  final _servidor = const ServidorColaborador();
  final _controladorNotas = TextEditingController();
  
  String _tipoAtribuicao = 'livre'; // 'livre', 'mim', 'outro'
  String? _colaboradorSelecionadoId;
  String _destino = 'avancar'; // 'avancar', 'prova_clinica', 'standby'
  List<Colaborador> _colaboradores = [];
  bool _aCarregarColaboradores = true;
  bool _aSubmeter = false;

  @override
  void initState() {
    super.initState();
    _carregarColaboradores();
  }

  Future<void> _carregarColaboradores() async {
    try {
      final lista = await _servidor.obterColaboradores();
      if (!mounted) return;
      setState(() {
        _colaboradores = lista;
        _aCarregarColaboradores = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _aCarregarColaboradores = false);
    }
  }

  Future<void> _concluir() async {
    if (_tipoAtribuicao == 'outro' && _colaboradorSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o colaborador que receberá a próxima etapa.')),
      );
      return;
    }

    setState(() => _aSubmeter = true);
    
    await _servidor.concluirEtapa(
      widget.trabalho.id,
      atribuicao: _tipoAtribuicao,
      colaboradorId: _colaboradorSelecionadoId,
      nota: _controladorNotas.text,
      destino: _destino,
    );
    
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etapa atualizada com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etapaAtual = widget.trabalho.etapaAtiva?.nome ?? 'Atual';
    final etapas = widget.trabalho.etapas;
    final indiceAtual = etapas.indexWhere((e) => e.estado == 'em_execucao' || e.estado == 'execucao');
    String textoProximaEtapa;
    
    if (indiceAtual != -1 && indiceAtual < etapas.length - 1) {
      textoProximaEtapa = 'Próxima Etapa: ${etapas[indiceAtual + 1].nome}';
    } else {
      textoProximaEtapa = 'Trabalho concluído — última etapa';
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Concluir Etapa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              'Etapa atual: $etapaAtual',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              textoProximaEtapa,
              style: const TextStyle(color: CoresApp.textoSuave, fontSize: 13),
            ),
            const SizedBox(height: 20),

            const Text(
              'Atribuição da Próxima Etapa:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: ['livre', 'mim', 'outro'].contains(_tipoAtribuicao) ? _tipoAtribuicao : 'livre',
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'livre', child: Text('Deixar livre')),
                DropdownMenuItem(value: 'mim', child: Text('Atribuir a Mim')),
                DropdownMenuItem(value: 'outro', child: Text('Atribuir a Outro Colaborador')),
              ],
              onChanged: (val) {
                setState(() => _tipoAtribuicao = val ?? 'livre');
              },
            ),

            if (_tipoAtribuicao == 'outro') ...[
              const SizedBox(height: 12),
              _aCarregarColaboradores
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _colaboradorSelecionadoId,
                      hint: const Text('Colaborador da próxima etapa'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _colaboradores.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nome),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _colaboradorSelecionadoId = val),
                    ),
            ],

            const SizedBox(height: 20),

            const Text(
              'Notas de Transição / Observações para a Próxima Etapa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              '🔒 Nota de transição: Interna — não visível à clínica.',
              style: TextStyle(color: CoresApp.textoSuave, fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controladorNotas,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escreva observações opcionais...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Outras opções: prova clínica ou standby',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: ['avancar', 'prova_clinica', 'standby'].contains(_destino) ? _destino : 'avancar',
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'avancar', child: Text('Avançar na sequência de produção')),
                DropdownMenuItem(value: 'prova_clinica', child: Text('Enviar para Prova Clínica')),
                DropdownMenuItem(value: 'standby', child: Text('Colocar em standby')),
              ],
              onChanged: (val) => setState(() => _destino = val ?? 'avancar'),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _aSubmeter ? null : _concluir,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _aSubmeter
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Concluir Etapa', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}