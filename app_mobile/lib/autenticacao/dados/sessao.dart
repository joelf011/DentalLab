import 'package:app_mobile/cliente/dados/clinica.dart';

// As duas vistas da app. O Administrador entra na vista do colaborador.
enum Perfil { cliente, colaborador }

// Quem tem a sessão iniciada.
class Sessao {
  const Sessao({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.cargo = '',
    this.clinica,
    this.token,
  });

  final String id;
  final String nome;
  final String email;
  final Perfil perfil;
  final String cargo; // Cliente | Colaborador | Administrador
  final Clinica? clinica; // só no perfil cliente
  final String? token; // enviado nos pedidos à API

  // Sessão atual: preenchida no login e apagada ao terminar sessão.
  // Qualquer ecrã pode ler, por exemplo: Sessao.atual!.nome
  static Sessao? atual;
}
