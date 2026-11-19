// Um colaborador do laboratório.
class Colaborador {
  const Colaborador({
    required this.id,
    required this.nome,
    required this.email,
    this.estado = 'disponivel',
  });

  final String id;
  final String nome;
  final String email;
  final String estado; // disponivel | ocupado | ausente
}
