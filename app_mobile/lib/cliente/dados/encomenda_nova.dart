// Dados preenchidos na Nova encomenda, antes de serem enviados.

// Um tipo de trabalho do catálogo do laboratório.
class TipoTrabalho {
  const TipoTrabalho({
    required this.id,
    required this.nome,
    required this.natureza,
  });

  final String id;
  final String nome;
  final String natureza; // Físico | Digital
}

// A encomenda: um paciente com um ou mais trabalhos.
class EncomendaNova {
  const EncomendaNova({
    required this.clinicaId,
    required this.medico,
    required this.paciente,
    required this.trabalhos,
    this.idade,
    this.sexo,
  });

  final String clinicaId;
  final String medico;
  final String paciente; // identificação
  final int? idade;
  final String? sexo; // masculino | feminino | outro
  final List<TrabalhoNovo> trabalhos;
}

// Um trabalho dentro da encomenda.
class TrabalhoNovo {
  const TrabalhoNovo({
    required this.tipo,
    this.cor,
    this.dentes = const [],
    this.descricao,
    this.ficheiros = const [],
    this.fotografias = const [],
  });

  final TipoTrabalho tipo;
  final String? cor;
  final List<int> dentes;
  final String? descricao;
  final List<String> ficheiros; // caminhos dos ficheiros STL / ZIP
  final List<String> fotografias; // caminhos das fotografias
}
