import 'package:flutter/material.dart';

import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/colaborador/dados/colaborador.dart';
import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/widget_cabecalho_janela.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';

// Janela "Concluir Etapa": etapa atual -> próxima etapa, a quem atribuir
// (livre / a mim / outro colaborador), nota interna e destino
// (avançar / prova clínica / standby).
//
// Abre-se com: mostrarJanelaConcluirEtapa(context, trabalho)
Future<void> mostrarJanelaConcluirEtapa(
  BuildContext context,
  Trabalho trabalho,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => JanelaConcluirEtapa(trabalho: trabalho),
  );
}

class JanelaConcluirEtapa extends StatefulWidget {
  const JanelaConcluirEtapa({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<JanelaConcluirEtapa> createState() => _JanelaConcluirEtapaState();
}

class _JanelaConcluirEtapaState extends State<JanelaConcluirEtapa> {
  final _servidor = const ServidorColaborador();
  final _formulario = GlobalKey<FormState>();
  late TextEditingController _controladorNota;
  late TextEditingController _controladorMotivo;
  late Future<List<Colaborador>> _futuroColaboradores;
  String _atribuicao = 'livre'; // livre | eu | outro
  int? _colaboradorId;
  String _destino = 'avancar'; // avancar | prova | standby
  bool _aGuardar = false;

  @override
  void initState() {
    super.initState();
    _controladorNota = TextEditingController();
    _controladorMotivo = TextEditingController();
    _futuroColaboradores = _servidor.obterColaboradores();
  }

  @override
  void dispose() {
    _controladorNota.dispose();
    _controladorMotivo.dispose();
    super.dispose();
  }

  // A etapa seguinte à atual, ou null se a atual for a última.
  EtapaTrabalho? get _proximaEtapa {
    final etapas = widget.trabalho.etapas;
    final atual = widget.trabalho.etapaAtual;
    if (atual == null) return null;
    final indice = etapas.indexOf(atual);
    if (indice < 0 || indice + 1 >= etapas.length) return null;
    return etapas[indice + 1];
  }

  void _fechar() {
    Navigator.pop(context);
  }

  void _mudarAtribuicao(String? valor) {
    setState(() {
      _atribuicao = valor ?? 'livre';
    });
  }

  void _mudarColaborador(int? valor) {
    setState(() {
      _colaboradorId = valor;
    });
  }

  void _mudarDestino(String? valor) {
    setState(() {
      _destino = valor ?? 'avancar';
    });
  }

  String? _validarColaborador(int? valor) {
    // Em standby a etapa não avança: não é preciso escolher ninguém.
    if (_destino != 'standby' && _atribuicao == 'outro' && valor == null) {
      return 'Selecione o colaborador que receberá a próxima etapa.';
    }
    return null;
  }

  String? _validarMotivo(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'A justificação é obrigatória para standby.';
    }
    return null;
  }

  // Avançar ou prova: conclui a etapa. Standby: a ordem fica "Em espera"
  // e a etapa atual fica suspensa, sem avançar.
  Future<void> _guardar() async {
    final etapa = widget.trabalho.etapaAtual;
    if (etapa == null || !_formulario.currentState!.validate()) return;
    setState(() {
      _aGuardar = true;
    });
    final mensageiro = ScaffoldMessenger.of(context);
    final String mensagem;
    if (_destino == 'standby') {
      await _servidor.colocarEmEspera(
        widget.trabalho.ordemTrabalhoId,
        _controladorMotivo.text.trim(),
      );
      mensagem = 'Trabalho colocado em standby';
    } else {
      await _servidor.concluirEtapa(
        etapa.id,
        atribuicao: _atribuicao,
        colaboradorId: _atribuicao == 'outro' ? _colaboradorId : null,
        nota: _controladorNota.text.trim(),
        destino: _destino,
      );
      mensagem = 'Etapa atualizada com sucesso';
    }
    if (!mounted) return;
    Navigator.pop(context);
    mensageiro.showSnackBar(SnackBar(content: Text(mensagem)));
  }

  InputDecoration _decoracao() {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etapaAtual = widget.trabalho.etapaAtual?.nome ?? '—';
    final proxima = _proximaEtapa;
    final standby = _destino == 'standby';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CabecalhoJanela(titulo: 'Concluir Etapa', aoFechar: _fechar),
                Text(
                  'Etapa atual: $etapaAtual',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  proxima != null
                      ? 'Próxima Etapa: ${proxima.nome}'
                      : 'Trabalho concluído — última etapa',
                  style: const TextStyle(
                    color: CoresApp.textoSuave,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // A quem fica a próxima etapa (só se houver próxima)
                if (proxima != null) ...[
                  const Text(
                    'Atribuição da Próxima Etapa:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _atribuicao,
                    isExpanded: true,
                    decoration: _decoracao(),
                    items: const [
                      DropdownMenuItem(
                        value: 'livre',
                        child: Text('Deixar livre'),
                      ),
                      DropdownMenuItem(
                        value: 'eu',
                        child: Text('Atribuir a Mim'),
                      ),
                      DropdownMenuItem(
                        value: 'outro',
                        child: Text('Atribuir a Outro Colaborador'),
                      ),
                    ],
                    onChanged: _mudarAtribuicao,
                  ),
                  if (_atribuicao == 'outro') ...[
                    const SizedBox(height: 12),
                    _escolherColaborador(),
                  ],
                  const SizedBox(height: 20),
                ],

                CampoTexto(
                  etiqueta: 'Notas de transição / observações',
                  controlador: _controladorNota,
                  dica: 'Observações para a próxima etapa (opcional)',
                  linhas: 3,
                ),
                const SizedBox(height: 4),
                const Text(
                  '🔒 Nota de transição: Interna — não visível à clínica.',
                  style: TextStyle(color: CoresApp.textoSuave, fontSize: 11),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Outras opções: prova clínica ou standby',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _destino,
                  isExpanded: true,
                  decoration: _decoracao(),
                  items: const [
                    DropdownMenuItem(
                      value: 'avancar',
                      child: Text('Avançar na sequência de produção'),
                    ),
                    DropdownMenuItem(
                      value: 'prova',
                      child: Text('Enviar para Prova Clínica'),
                    ),
                    DropdownMenuItem(
                      value: 'standby',
                      child: Text('Colocar em standby'),
                    ),
                  ],
                  onChanged: _mudarDestino,
                ),
                if (standby) ...[
                  const SizedBox(height: 16),
                  CampoTexto(
                    etiqueta: 'Justificação obrigatória',
                    controlador: _controladorMotivo,
                    dica:
                        'Explique porque precisa de colocar o trabalho em standby…',
                    linhas: 4,
                    validador: _validarMotivo,
                  ),
                ],
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _aGuardar ? null : _fechar,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _aGuardar ? null : _guardar,
                        style: FilledButton.styleFrom(
                          backgroundColor: CoresApp.sucesso,
                          foregroundColor: CoresApp.superficie,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          standby ? 'Colocar em standby' : 'Concluir Etapa',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Lista "Colaborador da próxima etapa" (sem quem tem sessão).
  Widget _escolherColaborador() {
    return FutureBuilder<List<Colaborador>>(
      future: _futuroColaboradores,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final eu = Sessao.atual!.id;
          final outros = snapshot.data!
              .where((colaborador) => colaborador.id != eu)
              .toList();
          return DropdownButtonFormField<int>(
            initialValue: _colaboradorId,
            isExpanded: true,
            hint: const Text('Colaborador da próxima etapa'),
            decoration: _decoracao(),
            items: [
              for (final colaborador in outros)
                DropdownMenuItem(
                  value: colaborador.id,
                  child: Text(colaborador.nome),
                ),
            ],
            onChanged: _mudarColaborador,
            validator: _validarColaborador,
          );
        } else if (snapshot.hasError) {
          return const Text('Não foi possível obter os colaboradores.');
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
