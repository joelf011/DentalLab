// Dados preenchidos na Nova encomenda, antes de serem enviados
// (POST /api/ordens e POST /api/ordens/:id/trabalhos).

// Um tipo de trabalho do catálogo (vista vw_tipo_trabalho).
class TipoTrabalho {
  const TipoTrabalho({required this.id, required this.nome, this.descricao});

  final int id;
  final String nome;
  final String? descricao;
}

// A encomenda (ordem_trabalho): um paciente com um ou mais trabalhos.
// Os ficheiros e as fotografias ficam ligados à ordem, para a clínica
// continuar a vê-los (os ficheiros de um trabalho são internos do laboratório).
class EncomendaNova {
  const EncomendaNova({
    required this.medico,
    required this.trabalhos,
    this.paciente,
    this.sexoPaciente,
    this.idadePaciente,
    this.dataProximaConsulta,
    this.observacoes,
    this.ficheiros = const [],
    this.fotografias = const [],
  });

  final String medico; // nome_medico_responsavel (obrigatório)
  final String? paciente; // nome_paciente
  final String? sexoPaciente; // M | F
  final int? idadePaciente; // 0 a 130
  final DateTime? dataProximaConsulta;
  final String? observacoes;
  final List<TrabalhoNovo> trabalhos;
  final List<String> ficheiros; // caminhos dos ficheiros STL / ZIP
  final List<String> fotografias; // caminhos das fotografias
}

// Um trabalho dentro da encomenda (tabela trabalho).
class TrabalhoNovo {
  const TrabalhoNovo({
    required this.tipo,
    required this.natureza,
    this.cor,
    this.dentes = const [],
  });

  final TipoTrabalho tipo;
  final String natureza; // FISICO | DIGITAL
  final String? cor; // até 10 caracteres, ex.: A2
  final List<int> dentes; // numeração FDI
}
