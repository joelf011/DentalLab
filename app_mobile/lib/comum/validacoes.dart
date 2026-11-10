// Validações dos campos dos formulários (parâmetro validator do TextFormField).
// Devolvem null se o valor estiver certo, ou a mensagem de erro.

String? validarObrigatorio(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Preencha este campo.';
  return null;
}

String? validarEmail(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Introduza o e-mail.';
  final formato = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!formato.hasMatch(valor.trim())) return 'Introduza um e-mail válido.';
  return null;
}

String? validarPalavraPasse(String? valor) {
  if (valor == null || valor.length < 8) return 'Use pelo menos 8 caracteres.';
  return null;
}
