import 'package:flutter/material.dart';

// Todas as cores da app (cores do protótipo do Figma).
// Nos ecrãs usa-se sempre CoresApp.dourado, CoresApp.textoSuave, ...
// tal como se usa Colors.blue. Não escrever Color(0xFF...) nos ecrãs.
class CoresApp {
  static const dourado = Color(0xFFC9A227); // botões principais
  static const douradoEscuro = Color(0xFF8A6F14); // texto sobre dourado claro
  static const douradoClaro = Color(0xFFF7F2E7); // fundos suaves
  static const fundo = Color(0xFFF3F4F6); // fundo dos ecrãs
  static const superficie = Color(0xFFFFFFFF); // cartões e barras
  static const textoForte = Color(0xFF1F2937); // títulos
  static const texto = Color(0xFF475569); // texto normal
  static const textoSuave = Color(0xFF64748B); // legendas
  static const linha = Color(0xFFE5E7EB); // contornos e divisões
  static const sucesso = Color(0xFF047857); // concluído
  static const sucessoClaro = Color(0xFFECFDF5);
  static const info = Color(0xFF1D4ED8); // em processamento
  static const infoClaro = Color(0xFFEFF6FF);
  static const aviso = Color(0xFFB45309); // em espera / prazo próximo
  static const avisoClaro = Color(0xFFFFFBEB);
  static const erro = Color(0xFFB91C1C); // erros / atraso
  static const erroClaro = Color(0xFFFEF2F2);
}
