// Uma clínica (conta de cliente).
class Clinica {
  const Clinica({
    required this.id,
    required this.nome,
    required this.email,
    this.nif,
    this.telefone,
    this.morada,
    this.estado = 'ativo',
  });

  final String id;
  final String nome;
  final String email;
  final String? nif;
  final String? telefone;
  final String? morada;
  final String estado; // ativo | suspenso | aguarda_validacao
}
