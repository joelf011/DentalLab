import 'package:app_mobile/comum/formatar_datas.dart';

// Uma etapa da produção de um trabalho.
class EtapaTrabalho {
  const EtapaTrabalho({
    required this.nome,
    this.estado = 'nao_iniciado',
    this.colaboradorId,
    this.colaboradorNome,
    this.iniciadaEm,
  });

  final String nome;
  final String estado; // nao_iniciado | em_execucao | concluida | standby
  final String? colaboradorId;
  final String? colaboradorNome;
  final DateTime? iniciadaEm;
}

// Um trabalho, tal como o laboratório o vê.
class Trabalho {
  const Trabalho({
    required this.id,
    required this.referencia,
    required this.descricao,
    required this.clinica,
    required this.tipo,
    required this.prazo,
    required this.estado,
    required this.etapaAtual,
    required this.etapas,
    this.natureza = 'Físico',
    this.responsavelId,
    this.cor,
    this.dentes = const [],
  });

  final String id;
  final String referencia; // LCD-2026-0847
  final String descricao;
  final String clinica; // nome da clínica
  final String tipo;
  final DateTime prazo;
  // por_receber | encaminhado | em_producao | em_standby | aguarda_aprovacao | concluido
  final String estado;
  final String etapaAtual; // nome da etapa atual
  final List<EtapaTrabalho> etapas;
  final String natureza; // Físico | Digital
  final String? responsavelId; // colaborador que tem o trabalho
  final String? cor;
  final List<int> dentes;

  // ── Regras (iguais às do protótipo, mockWorkStore.ts) ──

  // Etapa que está a ser feita agora (ou null).
  EtapaTrabalho? get etapaAtiva {
    for (final etapa in etapas) {
      if (etapa.estado == 'em_execucao') return etapa;
    }
    return null;
  }

  // Disponível: ninguém está a trabalhar nele e a etapa seguinte está livre.
  bool get estaDisponivel {
    if (estado != 'encaminhado' && estado != 'em_producao') return false;
    if (etapaAtiva != null) return false;
    for (final etapa in etapas) {
      if (etapa.estado == 'nao_iniciado' || etapa.estado == 'standby') {
        return etapa.colaboradorId == null;
      }
    }
    return false;
  }

  // O colaborador está a executar a etapa atual deste trabalho.
  bool estaEmExecucaoPor(String colaboradorId) =>
      estado == 'em_producao' &&
      responsavelId == colaboradorId &&
      etapaAtiva?.colaboradorId == colaboradorId;

  // Faltam 3 dias ou menos (ou já passou) e ainda não está concluído.
  bool get eUrgente => estado != 'concluido' && diasAte(prazo) <= 3;
}
