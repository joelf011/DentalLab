import 'package:flutter/material.dart';

// Logótipo do laboratório. Usar sempre este widget em vez de Image.asset.
// Exemplo: const Logotipo(largura: 190)
class Logotipo extends StatelessWidget {
  const Logotipo({super.key, this.largura = 72});

  final double largura;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: largura,
      height: largura * 0.55,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: Image.asset(
            'images/logo.png',
            width: largura,
            height: largura,
          ),
        ),
      ),
    );
  }
}
