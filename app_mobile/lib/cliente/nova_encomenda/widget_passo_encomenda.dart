import 'package:flutter/material.dart';

import 'package:app_mobile/comum/validacoes.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';

class PassoEncomenda extends StatefulWidget {
  const PassoEncomenda({
    super.key,
    required this.chaveFormulario,
    required this.medico,
    required this.identificacao,
    required this.idade,
    required this.sexo,
    required this.aoMudarSexo,
  });

  final GlobalKey<FormState> chaveFormulario;
  final TextEditingController medico;
  final TextEditingController identificacao;
  final TextEditingController idade;
  final String? sexo;
  final ValueChanged<String?> aoMudarSexo;

  @override
  State<PassoEncomenda> createState() => _PassoEncomendaState();
}

class _PassoEncomendaState extends State<PassoEncomenda> {
  String? _validarIdade(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    final idade = int.tryParse(valor.trim());
    if (idade == null || idade < 0 || idade > 120) {
      return 'Use uma idade de 0 a 120.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.chaveFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          const Text(
            'Estes dados identificam a encomenda. O médico fica associado apenas a esta encomenda.',
            style: TextStyle(height: 1.6),
          ),
          CampoTexto(
            etiqueta: 'Médico responsável',
            controlador: widget.medico,
            dica: 'Nome do médico responsável por esta encomenda',
            validador: validarObrigatorio,
          ),
          CampoTexto(
            etiqueta: 'Identificação',
            controlador: widget.identificacao,
            dica: 'Nome, referência ou código interno',
            validador: validarObrigatorio,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: CampoTexto(
                  etiqueta: 'Idade',
                  controlador: widget.idade,
                  dica: 'Anos',
                  teclado: TextInputType.number,
                  validador: _validarIdade,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SEXO', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: widget.sexo,
                      isExpanded: true,
                      hint: const Text('Selecionar…'),
                      items: const [
                        DropdownMenuItem(
                          value: 'masculino',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'feminino',
                          child: Text('Feminino'),
                        ),
                        DropdownMenuItem(value: 'outro', child: Text('Outro')),
                      ],
                      onChanged: widget.aoMudarSexo,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
