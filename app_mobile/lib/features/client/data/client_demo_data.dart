// Dados locais do protótipo. Substituir por dados da API quando estiver disponível.
class ClientClinic {
  const ClientClinic({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}

class ClientOrder {
  const ClientOrder({
    required this.id,
    required this.clinicId,
    required this.reference,
    required this.type,
    required this.patient,
    required this.status,
    required this.stage,
    this.delivery,
  });

  final String id;
  final String clinicId;
  final String reference;
  final String type;
  final String patient;
  final String status;
  final String stage;
  final String? delivery;

  String get statusLabel => switch (status) {
    'por_receber' => 'Por receber',
    'encaminhado' => 'Encaminhado',
    'em_producao' => 'Em produção',
    'em_standby' => 'Em espera',
    'aguarda_aprovacao' => 'Aguarda aprovação',
    'concluido' => 'Concluído',
    _ => status,
  };
}

const demoClinics = [
  ClientClinic(
    id: 'c1',
    name: 'Clínica Dental Horizonte',
    email: 'geral@horizonte.pt',
  ),
  ClientClinic(
    id: 'c2',
    name: 'Consultório Dr. Lopes',
    email: 'slopesclinica@gmail.com',
  ),
];

const demoOrders = [
  ClientOrder(
    id: 'w1',
    clinicId: 'c1',
    reference: 'LCD-2024-0847',
    type: 'Coroa de zircónia',
    patient: '#PAC-0847',
    status: 'em_producao',
    stage: 'Enceramento',
    delivery: '03/11',
  ),
  ClientOrder(
    id: 'w2',
    clinicId: 'c2',
    reference: 'LCD-2024-0848',
    type: 'Prótese Parcial Removível',
    patient: '#PAC-0914',
    status: 'em_standby',
    stage: 'Aguarda impressão',
  ),
  ClientOrder(
    id: 'w4',
    clinicId: 'c1',
    reference: 'LCD-2024-0844',
    type: 'Coroa de feldspato',
    patient: '#PAC-0765',
    status: 'concluido',
    stage: 'Entregue',
    delivery: '31/10',
  ),
  ClientOrder(
    id: 'demo-1',
    clinicId: 'c1',
    reference: 'LCD-2024-0851',
    type: 'Goteira',
    patient: '#PAC-0851',
    status: 'por_receber',
    stage: 'A aguardar receção',
  ),
  ClientOrder(
    id: 'demo-2',
    clinicId: 'c1',
    reference: 'LCD-2024-0852',
    type: 'Coroa',
    patient: '#PAC-0852',
    status: 'encaminhado',
    stage: 'Encaminhado',
  ),
  ClientOrder(
    id: 'demo-3',
    clinicId: 'c1',
    reference: 'LCD-2024-0853',
    type: 'Faceta',
    patient: '#PAC-0853',
    status: 'por_receber',
    stage: 'A aguardar receção',
  ),
];
