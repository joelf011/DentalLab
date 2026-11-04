import 'package:flutter/material.dart';

import '../../client/data/client_demo_data.dart';
import '../../client/presentation/client_shell.dart';

enum _Screen { login, register, pending }

const _gold = Color(0xFFC9A227);
const _ink = Color(0xFF1F2937);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE5E7EB);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginForm = GlobalKey<FormState>();
  final _registerForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _nif = TextEditingController();
  final _phone = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  _Screen _screen = _Screen.login;
  int _step = 1;
  bool _loading = false;
  bool _dark = false;
  String? _error;

  @override
  void dispose() {
    for (final field in [
      _email,
      _password,
      _name,
      _address,
      _nif,
      _phone,
      _registerEmail,
      _registerPassword,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;
    final temporaryClinicLogin = email == 'clinica' && password == '123';
    final valid =
        temporaryClinicLogin ||
        (['geral@horizonte.pt', 'slopesclinica@gmail.com'].contains(email) &&
            password == 'clinica') ||
        ([
              'ana@lcd.pt',
              'pedro@lcd.pt',
              'jorge@lcd.pt',
              'marta@lcd.pt',
            ].contains(email) &&
            password == 'colaborador') ||
        (email == 'catarina@lcd.pt' && password == 'admin');
    setState(() {
      _loading = false;
      if (!valid) _error = 'Credenciais inválidas.';
    });
    if (valid) {
      final clinic = temporaryClinicLogin
          ? demoClinics.first
          : demoClinics.where((item) => item.email == email).firstOrNull;
      if (clinic != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ClientShell(clinic: clinic)),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acesso de demonstração validado. A área autenticada ainda não está ligada.',
          ),
        ),
      );
    }
  }

  void _next() {
    if (!_registerForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (_step == 1) {
        _step = 2;
      } else {
        _screen = _Screen.pending;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final background = _dark
        ? const Color(0xFF111827)
        : const Color(0xFFF3F4F6);
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _screen == _Screen.login
            ? _buildLogin()
            : _screen == _Screen.register
            ? _buildRegister()
            : _buildPending(),
      ),
    );
  }

  Widget _buildLogin() => Stack(
    children: [
      Positioned(
        top: 8,
        right: 16,
        child: IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.all(8),
          tooltip: _dark ? 'Tema claro' : 'Tema escuro',
          onPressed: () => setState(() => _dark = !_dark),
          icon: Icon(
            _dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: _muted,
          ),
        ),
      ),
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _logo(),
                const SizedBox(height: 16),
                Text(
                  'Bem-vindo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _loginForm,
                  child: Column(
                    children: [
                      _field(
                        'E-mail ou utilizador',
                        _email,
                        hint: 'nome@email.pt ou clinica',
                        keyboard: TextInputType.emailAddress,
                        validator: _loginIdentifierValidator,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        'Palavra-passe',
                        _password,
                        hint: '••••••••',
                        obscure: true,
                        validator: _required,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x1AEF4444),
                            border: Border.all(color: const Color(0x40EF4444)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '✕  $_error',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _button(
                        _loading ? '◌  A verificar...' : 'Entrar',
                        _loading ? null : _login,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    side: const BorderSide(color: _gold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => setState(() {
                    _step = 1;
                    _screen = _Screen.register;
                  }),
                  child: const Text(
                    'Registar clínica',
                    style: TextStyle(fontSize: 14, color: _gold),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Crie a conta da sua clínica ou consultório.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: _muted),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildRegister() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.all(8),
                  onPressed: () => setState(() {
                    if (_step == 1) {
                      _screen = _Screen.login;
                    } else {
                      _step = 1;
                    }
                  }),
                  icon: const Icon(Icons.arrow_back, color: _muted),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASSO $_step DE 2',
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: _muted,
                      ),
                    ),
                    Text(
                      _step == 1 ? 'Dados da clínica' : 'Dados de acesso',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 15,
                        color: _text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: List.generate(
                2,
                (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: i < _step ? _gold : _border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _registerForm,
                  child: Column(
                    children: _step == 1
                        ? [
                            _field(
                              'Nome da clínica / consultório',
                              _name,
                              hint: 'Ex: Clínica Dental XYZ',
                              validator: _required,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'Morada',
                              _address,
                              hint: 'Rua, nº, código postal, cidade',
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'NIF',
                              _nif,
                              hint: 'PT 500 000 000',
                              keyboard: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'Contacto',
                              _phone,
                              hint: '+351 200 000 000',
                              keyboard: TextInputType.phone,
                            ),
                          ]
                        : [
                            _field(
                              'E-mail',
                              _registerEmail,
                              hint: 'nome@clinica.pt',
                              keyboard: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'Palavra-passe',
                              _registerPassword,
                              hint: 'Mínimo 8 caracteres',
                              obscure: true,
                              validator: (v) => (v?.length ?? 0) < 8
                                  ? 'Use pelo menos 8 caracteres.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _surface,
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Após o registo, a sua conta ficará pendente de validação pelo laboratório Catarina Domingos. A validação não é apenas do NIF — toda a conta fica sujeita a aprovação do laboratório.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: _muted,
                                ),
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _button(_step == 1 ? 'Continuar' : 'Registar', _next),
          ],
        ),
      ),
    ),
  );

  Widget _buildPending() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384),
        child: Column(
          children: [
            _logo(),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: const Color(0x40C9A227)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0x26C9A227),
                    child: Icon(
                      Icons.hourglass_empty,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Conta a aguardar validação',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'O seu registo foi recebido nesta demonstração. A ligação ao laboratório para validar contas ainda não está disponível.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5, color: _muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              onPressed: () => setState(() => _screen = _Screen.login),
              child: const Text(
                '← Voltar ao início de sessão',
                style: TextStyle(fontSize: 14, color: _gold),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Color get _text => _dark ? const Color(0xFFF9FAFB) : _ink;
  Color get _surface => _dark ? const Color(0xFF1F2937) : Colors.white;
  Color get _fieldBorder => _dark ? const Color(0xFF111827) : Colors.white;

  Widget _logo() => Column(
    children: [
      SizedBox(
        width: 190,
        height: 85,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: Image.asset(
              'lib/assets/images/logo.png',
              width: 190,
              height: 190,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'LABORATÓRIO DE PRÓTESE DENTÁRIA',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, letterSpacing: 1.8, color: _muted),
      ),
    ],
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
    bool obscure = false,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 12, letterSpacing: 1.1, color: _muted),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        autocorrect: false,
        validator: validator,
        onFieldSubmitted: label == 'Palavra-passe' && _screen == _Screen.login
            ? (_) => _login()
            : null,
        style: TextStyle(fontSize: 14, color: _text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: _outline(_fieldBorder),
          enabledBorder: _outline(_fieldBorder),
          focusedBorder: _outline(_gold),
        ),
      ),
    ],
  );

  OutlineInputBorder _outline(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  Widget _button(String label, VoidCallback? action) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: _gold,
          foregroundColor: _ink,
          disabledBackgroundColor: _gold.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Preencha este campo.' : null;

  String? _loginIdentifierValidator(String? value) {
    if (value?.trim().toLowerCase() == 'clinica') return null;
    return _emailValidator(value);
  }

  String? _emailValidator(String? value) {
    if (value?.trim().isEmpty ?? true) return 'Introduza o e-mail.';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
        ? null
        : 'Introduza um e-mail válido.';
  }
}
