import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/clinica.dart';
import 'package:app_mobile/cliente/dados/dados_demo_cliente.dart';
import 'package:app_mobile/configuracao.dart';

// Pedidos de autenticação: login e registo de clínica.
// O url da API vem no construtor e cada pedido é uma tarefa assíncrona.
class ServidorAutenticacao {
  const ServidorAutenticacao({this.url = urlApi});

  final String url;

  // Devolve a sessão, ou null se o e-mail ou a palavra-passe estiverem errados.
  // Noutros erros (conta por aprovar, sem ligação...) lança uma Exception
  // com a mensagem a mostrar.
  Future<Sessao?> entrar(String identificador, String palavraPasse) async {
    if (usarDadosDemo) return _entrarDemo(identificador, palavraPasse);
    return _entrarNaApi(identificador, palavraPasse);
  }

  // Regista uma clínica. A conta fica a aguardar validação do laboratório.
  // Em caso de erro lança uma Exception com a mensagem a mostrar.
  Future<void> registarClinica({
    required String nome,
    required String nif,
    required String morada,
    required String telefone,
    required String email,
    required String palavraPasse,
  }) async {
    if (usarDadosDemo) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return;
    }
    // POST /api/auth/registo (backend/src/rotas/auth.ts)
    final resultado = await http.post(
      Uri.parse('$url/auth/registo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome.trim(),
        'nif': nif.trim(),
        'morada_faturacao': morada.trim(),
        'telefone': telefone.trim(),
        'email': email.trim(),
        'password': palavraPasse,
      }),
    );
    if (resultado.statusCode != 201) {
      final resposta = jsonDecode(resultado.body);
      throw Exception(resposta['erro'] ?? 'Não foi possível fazer o registo.');
    }
  }

  // POST /api/auth/login (backend/src/rotas/auth.ts)
  // Resposta: {"token": "...", "utilizador": {"id", "nome", "cargo", "cliente_id", "email"}}
  Future<Sessao?> _entrarNaApi(String email, String palavraPasse) async {
    final resultado = await http.post(
      Uri.parse('$url/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': palavraPasse}),
    );
    final resposta = jsonDecode(resultado.body);
    if (resultado.statusCode == 401) return null;
    if (resultado.statusCode != 200) {
      throw Exception(resposta['erro'] ?? 'Não foi possível iniciar sessão.');
    }

    final utilizador = resposta['utilizador'];
    final cargo = utilizador['cargo'].toString();
    final eCliente = cargo == 'Cliente';
    return Sessao(
      id: utilizador['id'].toString(),
      nome: utilizador['nome'].toString(),
      email: utilizador['email'].toString(),
      cargo: cargo,
      // Colaborador e Administrador entram os dois na vista do colaborador.
      perfil: eCliente ? Perfil.cliente : Perfil.colaborador,
      clinica: eCliente
          ? Clinica(
              id: utilizador['cliente_id'].toString(),
              nome: utilizador['nome'].toString(),
              email: utilizador['email'].toString(),
            )
          : null,
      token: resposta['token'].toString(),
    );
  }

  // Contas de demonstração:
  //   clinica / 123 (ou e-mail da clínica / clinica)
  //   colaborador / 123
  //   catarina@lcd.pt / admin (administrador)
  Future<Sessao?> _entrarDemo(String identificador, String palavraPasse) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final login = identificador.trim().toLowerCase();

    for (final clinica in clinicasDemo) {
      final atalho = login == 'clinica' && palavraPasse == '123';
      final completo = login == clinica.email && palavraPasse == 'clinica';
      if (atalho || completo) {
        return Sessao(
          id: 'u-${clinica.id}',
          nome: clinica.nome,
          email: clinica.email,
          cargo: 'Cliente',
          perfil: Perfil.cliente,
          clinica: clinica,
        );
      }
    }

    if (login == 'colaborador' && palavraPasse == '123') {
      return const Sessao(
        id: 's1',
        nome: 'Ana Martins',
        email: 'ana@lcd.pt',
        cargo: 'Colaborador',
        perfil: Perfil.colaborador,
      );
    }

    if (login == 'catarina@lcd.pt' && palavraPasse == 'admin') {
      return const Sessao(
        id: 'admin',
        nome: 'Catarina Domingos',
        email: 'catarina@lcd.pt',
        cargo: 'Administrador',
        perfil: Perfil.colaborador,
      );
    }

    return null;
  }
}
