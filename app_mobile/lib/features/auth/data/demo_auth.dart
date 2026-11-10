import '../../client/data/client_demo_data.dart';
import 'auth_service.dart';

// Implementação temporária: substituir por uma implementação da API.
class DemoAuth implements AuthService {
  const DemoAuth();

  @override
  Future<AuthSession?> signIn(String identifier, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final login = identifier.trim().toLowerCase();

    if (login == 'clinica' && password == '123') {
      final clinic = demoClinics.first;
      return AuthSession(
        name: clinic.name,
        email: clinic.email,
        role: AuthRole.client,
        clinic: clinic,
      );
    }

    for (final clinic in demoClinics) {
      if (login == clinic.email && password == 'clinica') {
        return AuthSession(
          name: clinic.name,
          email: clinic.email,
          role: AuthRole.client,
          clinic: clinic,
        );
      }
    }

    if (login == 'colaborador' && password == '123') {
      return const AuthSession(
        name: 'Colaborador',
        email: 'colaborador@demo.local',
        role: AuthRole.collaborator,
      );
    }

    return null;
  }
}
