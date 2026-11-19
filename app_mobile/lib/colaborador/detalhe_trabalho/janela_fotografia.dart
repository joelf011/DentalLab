import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_mobile/colaborador/dados/servidor_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/widget_cabecalho_janela.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

// Janela "Adicionar Fotografia": tirar com a câmara ou escolher da galeria
// (package image_picker), ver a fotografia e guardar.
//
// Abre-se com: mostrarJanelaFotografia(context, trabalho)
Future<void> mostrarJanelaFotografia(BuildContext context, Trabalho trabalho) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => JanelaFotografia(trabalho: trabalho),
  );
}

class JanelaFotografia extends StatefulWidget {
  const JanelaFotografia({super.key, required this.trabalho});

  final Trabalho trabalho;

  @override
  State<JanelaFotografia> createState() => _JanelaFotografiaState();
}

class _JanelaFotografiaState extends State<JanelaFotografia> {
  final _servidor = const ServidorColaborador();
  final _seletor = ImagePicker();
  XFile? _fotografia;
  Uint8List? _bytes; // a imagem em memória, para a mostrar (também na web)
  bool _aGuardar = false;

  void _fechar() {
    Navigator.pop(context);
  }

  Future<void> _escolher(ImageSource origem) async {
    try {
      final fotografia = await _seletor.pickImage(
        source: origem,
        maxWidth: 1600,
      );
      if (fotografia == null) return;
      final bytes = await fotografia.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fotografia = fotografia;
        _bytes = bytes;
      });
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a fotografia.')),
      );
    }
  }

  void _usarCamara() {
    _escolher(ImageSource.camera);
  }

  void _usarGaleria() {
    _escolher(ImageSource.gallery);
  }

  Future<void> _guardar() async {
    final fotografia = _fotografia;
    if (fotografia == null) return;
    setState(() {
      _aGuardar = true;
    });
    await _servidor.adicionarFotografia(widget.trabalho.id, fotografia.path);
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro.showSnackBar(
      const SnackBar(content: Text('Fotografia adicionada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CabecalhoJanela(
                titulo: 'Adicionar Fotografia',
                aoFechar: _fechar,
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CoresApp.fundo,
                  border: Border.all(color: CoresApp.linha, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_bytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _bytes!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: CoresApp.textoSuave,
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _usarCamara,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Câmara'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _usarGaleria,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeria'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _aGuardar ? null : _fechar,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      // Só se pode guardar depois de escolher a fotografia.
                      onPressed: _fotografia == null || _aGuardar
                          ? null
                          : _guardar,
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
