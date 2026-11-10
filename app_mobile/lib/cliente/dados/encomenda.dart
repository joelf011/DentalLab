// Uma encomenda, tal como a clínica a vê.
class Encomenda {
  const Encomenda({
    required this.id,
    required this.clinicaId,
    required this.referencia,
    required this.tipo,
    required this.paciente,
    required this.estado,
    required this.etapa,
    this.prazo,
    this.medico,
    this.material,
    this.cor,
    this.natureza = 'Físico',
    this.descricao,
    this.dentes = const [],
    this.etapas = const [],
    this.eventos = const [],
    this.mensagens = const [],
  });

  final String id;
  final String clinicaId;
  final String referencia; // LCD-2026-0847
  final String tipo; // Coroa, Goteira, ...
  final String paciente; // identificação do paciente
  // por_receber | encaminhado | em_producao | em_standby | aguarda_aprovacao | concluido
  final String estado;
  final String etapa; // etapa atual
  final DateTime? prazo; // prazo de entrega
  final String? medico;
  final String? material;
  final String? cor; // ex.: A2
  final String natureza; // Físico | Digital
  final String? descricao;
  final List<int> dentes;
  final List<EtapaEncomenda> etapas;
  final List<EventoEncomenda> eventos;
  final List<MensagemEncomenda> mensagens;
}

// Uma etapa da produção (a clínica só vê o nome e se já terminou).
class EtapaEncomenda {
  const EtapaEncomenda({required this.nome, this.concluida = false});

  final String nome;
  final bool concluida;
}

// Um acontecimento do histórico da encomenda.
class EventoEncomenda {
  const EventoEncomenda({
    required this.descricao,
    required this.autor,
    required this.data,
  });

  final String descricao;
  final String autor;
  final String data;
}

// Uma mensagem entre a clínica e o laboratório.
class MensagemEncomenda {
  const MensagemEncomenda({
    required this.autor,
    required this.texto,
    required this.data,
    this.daClinica = false,
  });

  final String autor;
  final String texto;
  final String data;
  final bool daClinica;
}
