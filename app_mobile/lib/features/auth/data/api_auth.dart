import 'dart:convert';
import 'dart:io';

import '../../client/data/client_clinic.dart';
import 'auth_service.dart';

/// Contrato proposto para POST /auth/login:
/// pedido: {"email": "...", "password": "..."}
/// sucesso (200): {"accessToken": "...", "user": {
///   "name": "...", "email": "...", "role": "Cliente" | "Colaborador",
///   "clinic": {"id": "...", "name": "...", "email": "..."} // só Cliente
/// }}
/// credenciais inválidas: 401. Outros erros lançam uma exceção.
class ApiAuth implements AuthService {
  const ApiAuth({required this.loginUrl});

  final Uri loginUrl;

  @override
  Future<AuthSession?> signIn(String identifier, String password) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(loginUrl);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({'email': identifier.trim(), 'password': password}),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.unauthorized) return null;
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Erro no login: HTTP ${response.statusCode}');
      }

      final payload = _object(jsonDecode(body));
      final user = _object(payload['user']);
      final role = switch (_requiredString(user, 'role')) {
        'Cliente' => AuthRole.client,
        'Colaborador' => AuthRole.collaborator,
        _ => throw const FormatException('Perfil não suportado pela app.'),
      };
      final clinic = role == AuthRole.client
          ? _readClinic(user['clinic'])
          : null;
      return AuthSession(
        name: _requiredString(user, 'name'),
        email: _requiredString(user, 'email'),
        role: role,
        clinic: clinic,
        accessToken: _requiredString(payload, 'accessToken'),
      );
    } finally {
      client.close(force: true);
    }
  }

  ClientClinic _readClinic(Object? value) {
    final clinic = _object(value);
    return ClientClinic(
      id: _requiredString(clinic, 'id'),
      name: _requiredString(clinic, 'name'),
      email: _requiredString(clinic, 'email'),
    );
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Resposta inválida da API.');
  }

  String _requiredString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.isNotEmpty) return value;
    if (key == 'id' && value is num) return value.toString();
    throw FormatException('Campo obrigatório em falta: $key');
  }
}
