import 'package:app_mobile/cliente/dados/clinica.dart';

// As duas vistas da app. O Administrador entra na vista do colaborador.
enum Perfil { cliente, colaborador }

// Quem tem a sessão iniciada (dados devolvidos por POST /api/auth/login).
class Sessao {
  const Sessao({
    required this.id,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.perfil,
    this.clinica,
    this.token,
  });

  final int id; // id do utilizador
  final String nome;
  final String email;
  final String cargo; // Administrador | Colaborador | Cliente (tabela cargo)
  final Perfil perfil;
  final Clinica? clinica; // só no perfil cliente
  final String? token; // enviado nos pedidos à API

  // Sessão atual: preenchida no login e apagada ao terminar sessão.
  // Qualquer ecrã pode ler, por exemplo: Sessao.atual!.nome
  static Sessao? atual;
}
