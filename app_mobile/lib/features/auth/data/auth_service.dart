import '../../client/data/client_clinic.dart';

enum AuthRole { client, collaborator }

class AuthSession {
  const AuthSession({
    required this.name,
    required this.email,
    required this.role,
    this.clinic,
    this.accessToken,
  });

  final String name;
  final String email;
  final AuthRole role;
  final ClientClinic? clinic;
  final String? accessToken;
}

abstract class AuthService {
  Future<AuthSession?> signIn(String identifier, String password);
}
