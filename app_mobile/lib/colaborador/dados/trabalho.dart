import 'package:app_mobile/comum/formatar_datas.dart';

// Modelos da vista do colaborador, iguais às vistas da base de dados:
// Trabalho = vw_trabalho + dados da ordem (cliente, estado, prazo),
// EtapaTrabalho = vw_etapa_trabalho.

// Uma etapa da produção de um trabalho.
class EtapaTrabalho {
  const EtapaTrabalho({
    required this.id,
    required this.nome,
    required this.ordem,
    this.responsavelId,
    this.responsavel,
    this.dataInicio,
    this.dataConclusao,
  });

  final int id;
  final String nome;
  final int ordem; // posição na sequência (1, 2, 3, ...)
  final int? responsavelId;
  final String? responsavel; // nome do colaborador
  final DateTime? dataInicio;
  final DateTime? dataConclusao;

  // Igual à coluna "estado" de vw_etapa_trabalho.
  String get estado {
    if (dataConclusao != null) return 'Concluída';
    if (dataInicio != null) return 'Em curso';
    return 'Por iniciar';
  }
}

// Um trabalho, tal como o laboratório o vê.
class Trabalho {
  const Trabalho({
    required this.id,
    required this.ordemTrabalhoId,
    required this.tipoTrabalho,
    required this.natureza,
    required this.cliente,
    required this.estadoOrdem,
    required this.etapas,
    this.cor,
    this.dentes = const [],
    this.prazoEntrega,
  });

  final int id;
  final int ordemTrabalhoId;
  final String tipoTrabalho;
  final String natureza; // FISICO | DIGITAL
  final String cliente; // nome da clínica
  final String estadoOrdem; // estado da ordem (tabela estado_ordem)
  final List<EtapaTrabalho> etapas; // por ordem
  final String? cor;
  final List<int> dentes;
  final DateTime? prazoEntrega;

  // ── Regras ──

  // Etapa atual: a primeira por concluir (como vw_trabalho_etapa_atual).
  EtapaTrabalho? get etapaAtual {
    for (final etapa in etapas) {
      if (etapa.dataConclusao == null) return etapa;
    }
    return null;
  }

  bool get estaFechado =>
      estadoOrdem == 'Concluído' ||
      estadoOrdem == 'Entregue' ||
      estadoOrdem == 'Rejeitado';

  // Disponível: a ordem está em produção e ninguém assumiu a etapa atual.
  bool get estaDisponivel {
    final etapa = etapaAtual;
    final emProducao =
        estadoOrdem == 'Por iniciar' || estadoOrdem == 'Em processamento';
    return emProducao && etapa != null && etapa.responsavelId == null;
  }

  // A etapa atual está atribuída a este colaborador.
  bool eDe(int colaboradorId) =>
      !estaFechado && etapaAtual?.responsavelId == colaboradorId;

  // O colaborador está a executar a etapa atual (já iniciada).
  bool estaEmExecucaoPor(int colaboradorId) =>
      estadoOrdem == 'Em processamento' &&
      etapaAtual?.responsavelId == colaboradorId &&
      etapaAtual?.dataInicio != null;

  // Faltam 3 dias ou menos (ou já passou) e ainda não está fechado.
  bool get eUrgente =>
      !estaFechado && prazoEntrega != null && diasAte(prazoEntrega!) <= 3;
}
