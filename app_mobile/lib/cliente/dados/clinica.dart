// Uma clínica (vista vw_cliente da base de dados).
class Clinica {
  const Clinica({
    required this.id,
    required this.nome,
    this.nif,
    this.moradaFaturacao,
    this.email,
    this.telefone,
    this.ativo = true,
  });

  final int id;
  final String nome;
  final String? nif;
  final String? moradaFaturacao;
  final String? email;
  final String? telefone;
  final bool ativo;
}
