// Dados locais do protótipo. Substituir por dados da API quando estiver disponível.
import 'client_clinic.dart';

export 'client_clinic.dart';

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
    this.doctor,
    this.material,
    this.shade,
    this.nature = 'Físico',
    this.description,
    this.teeth = const [],
    this.steps = const [],
    this.events = const [],
    this.messages = const [],
  });

  final String id;
  final String clinicId;
  final String reference;
  final String type;
  final String patient;
  final String status;
  final String stage;
  final String? delivery;
  final String? doctor;
  final String? material;
  final String? shade;
  final String nature;
  final String? description;
  final List<int> teeth;
  final List<ClientOrderStep> steps;
  final List<ClientOrderEvent> events;
  final List<ClientOrderMessage> messages;

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

class ClientOrderStep {
  const ClientOrderStep({required this.name, this.completed = false});

  final String name;
  final bool completed;
}

class ClientOrderEvent {
  const ClientOrderEvent({
    required this.description,
    required this.actor,
    required this.date,
  });

  final String description;
  final String actor;
  final String date;
}

class ClientOrderMessage {
  const ClientOrderMessage({
    required this.author,
    required this.text,
    required this.date,
    this.fromClinic = false,
  });

  final String author;
  final String text;
  final String date;
  final bool fromClinic;
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
    doctor: 'Dr. Rui Figueiredo',
    material: 'Zircónia',
    shade: 'A2',
    description: 'Coroa unitária. Verificar a oclusão cuidadosamente.',
    teeth: [15],
    steps: [
      ClientOrderStep(name: 'Receção', completed: true),
      ClientOrderStep(name: 'Análise técnica', completed: true),
      ClientOrderStep(name: 'Enceramento'),
      ClientOrderStep(name: 'Fresagem'),
      ClientOrderStep(name: 'Acabamento'),
      ClientOrderStep(name: 'Controlo de qualidade'),
      ClientOrderStep(name: 'Expedição'),
    ],
    events: [
      ClientOrderEvent(
        description: 'Encomenda recebida',
        actor: 'Laboratório',
        date: '10/12/2024',
      ),
      ClientOrderEvent(
        description: 'Encomenda encaminhada para produção',
        actor: 'Laboratório',
        date: '10/12/2024',
      ),
      ClientOrderEvent(
        description: 'Enceramento iniciado',
        actor: 'Laboratório',
        date: '11/12/2024',
      ),
    ],
    messages: [
      ClientOrderMessage(
        author: 'Laboratório',
        text: 'Trabalho em execução. O enceramento já foi iniciado.',
        date: '11/12/2024',
      ),
    ],
  ),
  ClientOrder(
    id: 'w2',
    clinicId: 'c2',
    reference: 'LCD-2024-0848',
    type: 'Prótese Parcial Removível',
    patient: '#PAC-0914',
    status: 'em_standby',
    stage: 'Aguarda impressão',
    doctor: 'Dr. Sérgio Lopes',
    material: 'Cromo-Cobalto',
    shade: 'A3',
    description:
        'Prótese parcial removível superior. A aguardar nova impressão.',
    teeth: [14, 15, 16, 17, 24, 25, 26],
    steps: [
      ClientOrderStep(name: 'Receção', completed: true),
      ClientOrderStep(name: 'Gesso'),
      ClientOrderStep(name: 'Estrutura metálica'),
      ClientOrderStep(name: 'Montagem de dentes'),
      ClientOrderStep(name: 'Expedição'),
    ],
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
    doctor: 'Dr. Rui Figueiredo',
    material: 'Cerâmica feldspática',
    shade: 'B1',
    description: 'Trabalho cerâmico para melhoramento estético.',
    teeth: [11, 12, 21, 22],
    steps: [
      ClientOrderStep(name: 'Receção', completed: true),
      ClientOrderStep(name: 'Análise técnica', completed: true),
      ClientOrderStep(name: 'Enceramento', completed: true),
      ClientOrderStep(name: 'Fresagem', completed: true),
      ClientOrderStep(name: 'Acabamento', completed: true),
      ClientOrderStep(name: 'Controlo de qualidade', completed: true),
      ClientOrderStep(name: 'Expedição', completed: true),
    ],
    events: [
      ClientOrderEvent(
        description: 'Encomenda recebida',
        actor: 'Laboratório',
        date: '05/12/2024',
      ),
      ClientOrderEvent(
        description: 'Trabalho concluído',
        actor: 'Laboratório',
        date: '14/12/2024',
      ),
    ],
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
