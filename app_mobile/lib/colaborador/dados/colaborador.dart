// Um utilizador interno do laboratório (vista vw_utilizador):
// Colaborador ou Administrador.
class Colaborador {
  const Colaborador({
    required this.id,
    required this.nome,
    required this.email,
    required this.cargo,
    this.ativo = true,
  });

  final int id;
  final String nome;
  final String email;
  final String cargo; // Colaborador | Administrador
  final bool ativo;
}
