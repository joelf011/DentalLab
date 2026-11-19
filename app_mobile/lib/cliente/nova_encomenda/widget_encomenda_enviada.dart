import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda_nova.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_linha_informacao.dart';

class EncomendaEnviada extends StatelessWidget {
  const EncomendaEnviada({
    super.key,
    required this.numero,
    required this.encomenda,
    required this.aoVerEncomendas,
    required this.aoNovaEncomenda,
  });

  final int numero; // devolvido por enviarEncomenda
  final EncomendaNova encomenda;
  final VoidCallback aoVerEncomendas;
  final VoidCallback aoNovaEncomenda;

  @override
  Widget build(BuildContext context) {
    final sexo = switch (encomenda.sexoPaciente) {
      'M' => 'Masculino',
      'F' => 'Feminino',
      _ => '—',
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: CoresApp.douradoClaro,
                  child: Icon(
                    Icons.check,
                    size: 40,
                    color: CoresApp.douradoEscuro,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Encomenda enviada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontFamily: 'serif'),
              ),
              const SizedBox(height: 12),
              const Text(
                'A encomenda e os respetivos trabalhos foram enviados para análise do laboratório.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.6, color: CoresApp.texto),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: CoresApp.superficie,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinhaInformacao(
                        etiqueta: 'Encomenda',
                        valor: 'n.º $numero',
                      ),
                      LinhaInformacao(
                        etiqueta: 'Identificação',
                        valor: encomenda.paciente,
                      ),
                      LinhaInformacao(
                        etiqueta: 'Idade',
                        valor: encomenda.idadePaciente == null
                            ? null
                            : '${encomenda.idadePaciente} anos',
                      ),
                      LinhaInformacao(etiqueta: 'Sexo', valor: sexo),
                      LinhaInformacao(
                        etiqueta: 'Médico responsável',
                        valor: encomenda.medico,
                      ),
                      LinhaInformacao(
                        etiqueta: 'Trabalhos',
                        valor:
                            '${encomenda.trabalhos.length} ${encomenda.trabalhos.length == 1 ? 'trabalho' : 'trabalhos'}',
                      ),
                      const Divider(),
                      for (final (indice, trabalho)
                          in encomenda.trabalhos.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${indice + 1}. ${trabalho.tipo.nome} — ${trabalho.dentes.length} ${trabalho.dentes.length == 1 ? 'dente' : 'dentes'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: CoresApp.texto,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: aoVerEncomendas,
                child: const Text('Ver Encomendas'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: aoNovaEncomenda,
                child: const Text('Nova Encomenda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
