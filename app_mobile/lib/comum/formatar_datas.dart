// Funções para mostrar datas sempre da mesma forma em toda a app.

// 03/11
String dataCurta(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';

// 03/11/2026
String dataCompleta(DateTime data) => '${dataCurta(data)}/${data.year}';

// 03/11/2026 14:30
String dataHora(DateTime data) =>
    '${dataCompleta(data)} ${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

// Dias que faltam até ao prazo (número negativo = prazo ultrapassado).
int diasAte(DateTime prazo) {
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(prazo.year, prazo.month, prazo.day);
  return dia.difference(hoje).inDays;
}

String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');
