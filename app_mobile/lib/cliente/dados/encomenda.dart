// Modelos da vista da clínica, iguais às vistas da base de dados:
// Encomenda = vw_ordem_trabalho, TrabalhoEncomenda = vw_trabalho,
// Comentario = comentário associado à ordem (partilhado com a clínica).
// A clínica não vê as etapas: são internas do laboratório.

// Estados da ordem (tabela estado_ordem).
const estadosOrdem = [
  'Em avaliação',
  'Rejeitado',
  'Por iniciar',
  'Em processamento',
  'Em espera',
  'Em prova',
  'Concluído',
  'Entregue',
];

class Encomenda {
  const Encomenda({
    required this.id,
    required this.clienteId,
    required this.estado,
    required this.medico,
    required this.dataCriacao,
    this.paciente,
    this.sexoPaciente,
    this.idadePaciente,
    this.dataProximaConsulta,
    this.observacoes,
    this.prazoEntrega,
    this.dataAceitacao,
    this.dataInicio,
    this.dataConclusao,
    this.dataEntrega,
    this.motivoEspera,
    this.motivoRejeicao,
    this.trabalhos = const [],
    this.comentarios = const [],
  });

  final int id;
  final int clienteId;
  final String estado; // um de estadosOrdem
  final String medico; // nome_medico_responsavel
  final DateTime dataCriacao;
  final String? paciente; // nome_paciente
  final String? sexoPaciente; // M | F
  final int? idadePaciente;
  final DateTime? dataProximaConsulta;
  final String? observacoes;
  final DateTime? prazoEntrega;
  final DateTime? dataAceitacao;
  final DateTime? dataInicio;
  final DateTime? dataConclusao;
  final DateTime? dataEntrega;
  final String? motivoEspera;
  final String? motivoRejeicao;
  final List<TrabalhoEncomenda> trabalhos;
  final List<Comentario> comentarios;

  // Texto curto dos trabalhos, para os cartões: "Coroa" ou "Coroa + 1".
  String get resumoTrabalhos {
    if (trabalhos.isEmpty) return 'Sem trabalhos';
    if (trabalhos.length == 1) return trabalhos.first.tipoTrabalho;
    return '${trabalhos.first.tipoTrabalho} + ${trabalhos.length - 1}';
  }

  // Histórico a partir das datas da ordem, do mais antigo ao mais recente.
  List<EventoEncomenda> get historico {
    final eventos = [
      EventoEncomenda(descricao: 'Encomenda criada', data: dataCriacao),
    ];
    if (dataAceitacao != null) {
      eventos.add(
        EventoEncomenda(
          descricao: 'Aceite pelo laboratório',
          data: dataAceitacao!,
        ),
      );
    }
    if (dataInicio != null) {
      eventos.add(
        EventoEncomenda(descricao: 'Produção iniciada', data: dataInicio!),
      );
    }
    if (dataConclusao != null) {
      eventos.add(
        EventoEncomenda(descricao: 'Encomenda concluída', data: dataConclusao!),
      );
    }
    if (dataEntrega != null) {
      eventos.add(
        EventoEncomenda(descricao: 'Encomenda entregue', data: dataEntrega!),
      );
    }
    return eventos;
  }
}

// Um trabalho dentro da encomenda.
class TrabalhoEncomenda {
  const TrabalhoEncomenda({
    required this.id,
    required this.tipoTrabalho,
    required this.natureza,
    this.cor,
    this.dentes = const [],
  });

  final int id;
  final String tipoTrabalho;
  final String natureza; // FISICO | DIGITAL
  final String? cor; // escala VITA, ex.: A2
  final List<int> dentes; // numeração FDI
}

// Comentário trocado entre a clínica e o laboratório sobre a encomenda.
class Comentario {
  const Comentario({
    required this.id,
    required this.autor,
    required this.conteudo,
    required this.dataCriacao,
    this.daClinica = false,
  });

  final int id;
  final String autor;
  final String conteudo;
  final DateTime dataCriacao;
  final bool daClinica;
}

// Um momento do histórico (calculado a partir das datas da ordem).
class EventoEncomenda {
  const EventoEncomenda({required this.descricao, required this.data});

  final String descricao;
  final DateTime data;
}
