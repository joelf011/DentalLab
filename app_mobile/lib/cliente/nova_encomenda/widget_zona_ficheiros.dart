import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

class ZonaFicheiros extends StatefulWidget {
  const ZonaFicheiros({
    super.key,
    required this.fotografias,
    required this.ficheiros,
    required this.aoMudar,
  });

  final bool fotografias;
  // Caminho (ou URI na web) e nome apresentado ao utilizador.
  final Map<String, String> ficheiros;
  final ValueChanged<Map<String, String>> aoMudar;

  @override
  State<ZonaFicheiros> createState() => _ZonaFicheirosState();
}

class _ZonaFicheirosState extends State<ZonaFicheiros> {
  bool _aEscolher = false;

  Future<void> _escolher() async {
    setState(() => _aEscolher = true);
    try {
      final novos = <String, String>{};
      if (widget.fotografias) {
        final imagens = await ImagePicker().pickMultiImage();
        for (final imagem in imagens) {
          novos[imagem.path] = imagem.name;
        }
      } else {
        final ficheiros = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['stl', 'zip'],
        );
        for (final ficheiro in ficheiros) {
          final extensao = ficheiro.extension?.toLowerCase();
          if (extensao == 'stl' || extensao == 'zip') {
            novos[ficheiro.path ?? ficheiro.uri.toString()] = ficheiro.name;
          }
        }
      }
      if (!mounted || novos.isEmpty) return;
      widget.aoMudar({...widget.ficheiros, ...novos});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o seletor. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _aEscolher = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.fotografias ? 'Fotografias' : 'Ficheiros STL ou ZIP';
    return Material(
      color: widget.fotografias ? CoresApp.superficie : CoresApp.douradoClaro,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: CoresApp.linha),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _aEscolher ? null : _escolher,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              spacing: 8,
              children: [
                if (_aEscolher)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    widget.fotografias
                        ? Icons.add_a_photo_outlined
                        : Icons.upload_file,
                    color: CoresApp.douradoEscuro,
                  ),
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.fotografias
                      ? 'Adicione fotografias clínicas ou de apoio'
                      : 'Selecione os ficheiros digitais',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CoresApp.textoSuave,
                  ),
                ),
                for (final nome in widget.ficheiros.values)
                  Text(
                    nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
