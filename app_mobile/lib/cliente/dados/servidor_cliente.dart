import 'package:app_mobile/cliente/dados/dados_demo_cliente.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/encomenda_nova.dart';
import 'package:app_mobile/cliente/dados/notificacao.dart';
import 'package:app_mobile/configuracao.dart';

// Pedidos de dados da vista da clínica. O url da API vem no construtor e
// cada método é uma tarefa assíncrona (Future).
// Enquanto usarDadosDemo for true, devolvem os dados de demonstração;
// depois passam a usar http.get / http.post + jsonDecode.
class ServidorCliente {
  const ServidorCliente({this.url = urlApi});

  final String url;

  // Simula o tempo de resposta da API.
  Future<void> _esperar() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  // Encomendas da clínica.
  Future<List<Encomenda>> obterEncomendas(String clinicaId) async {
    await _esperar();
    return encomendasDemo
        .where((encomenda) => encomenda.clinicaId == clinicaId)
        .toList();
  }

  // Notificações da clínica.
  Future<List<Notificacao>> obterNotificacoes(String clinicaId) async {
    await _esperar();
    final idsDaClinica = encomendasDemo
        .where((encomenda) => encomenda.clinicaId == clinicaId)
        .map((encomenda) => encomenda.id)
        .toSet();
    return notificacoesDemo
        .where((notificacao) => idsDaClinica.contains(notificacao.encomendaId))
        .toList();
  }

  // Catálogo de tipos de trabalho.
  Future<List<TipoTrabalho>> obterTiposTrabalho() async {
    await _esperar();
    return tiposTrabalhoDemo;
  }

  // Envia a encomenda e devolve a referência criada.
  Future<String> enviarEncomenda(EncomendaNova nova) async {
    await _esperar();
    final referencia =
        'ENC-${DateTime.now().year}-${encomendasDemo.length + 100}';
    // Na demonstração, a encomenda passa a aparecer nos Pedidos.
    encomendasDemo.add(
      Encomenda(
        id: referencia,
        clinicaId: nova.clinicaId,
        referencia: referencia,
        tipo: nova.trabalhos.first.tipo.nome,
        paciente: nova.paciente,
        estado: 'por_receber',
        etapa: 'A aguardar receção',
        medico: nova.medico,
      ),
    );
    return referencia;
  }

  // Envia uma mensagem ao laboratório.
  Future<void> enviarMensagem(String encomendaId, String texto) async {
    await _esperar();
  }
}
