import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/client_demo_data.dart';

const _gold = Color(0xFFC9A227);
const _ink = Color(0xFF1F2937);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE5E7EB);

class ClientOrderDetailPage extends StatefulWidget {
  const ClientOrderDetailPage({super.key, required this.order});

  final ClientOrder order;

  @override
  State<ClientOrderDetailPage> createState() => _ClientOrderDetailPageState();
}

class _ClientOrderDetailPageState extends State<ClientOrderDetailPage> {
  final _messageController = TextEditingController();
  late final List<ClientOrderMessage> _messages = [...widget.order.messages];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ClientOrderMessage(
          author: 'Clínica',
          text: text,
          date: 'Agora',
          fromClinic: true,
        ),
      );
      _messageController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensagem guardada apenas nesta demonstração.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            tooltip: 'Voltar às encomendas',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: _ink),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.reference,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
              Text(
                order.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: _ink),
              ),
            ],
          ),
          actions: [
            if (order.delivery != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Prazo ${order.delivery}',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _labelChip(_macroLabel(order.status), _gold),
                  _labelChip(order.nature, _muted),
                  Text(
                    order.type,
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            const Material(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _gold,
                unselectedLabelColor: _muted,
                indicatorColor: _gold,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Resumo', height: 48),
                  Tab(text: 'Progresso', height: 48),
                  Tab(text: 'Informação', height: 48),
                  Tab(text: 'Histórico', height: 48),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _content(_summary(order)),
                  _content(_progress(order)),
                  _content(_conversation()),
                  _content(_history(order)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(Widget child) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      ),
    ],
  );

  Widget _summary(ClientOrder order) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _panel(
        Column(
          children: [
            _infoRow('Médico', order.doctor),
            _infoRow('Identificação', order.patient),
            _infoRow('Material', order.material),
            _infoRow('Cor', order.shade),
            _infoRow('Prazo', order.delivery),
          ],
        ),
      ),
      if (order.description != null) ...[
        const SizedBox(height: 16),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DESCRIÇÃO',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 8),
              Text(
                order.description!,
                style: const TextStyle(fontSize: 14, color: _ink, height: 1.5),
              ),
            ],
          ),
        ),
      ],
      if (order.teeth.isNotEmpty) ...[
        const SizedBox(height: 16),
        _panel(
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Ver odontograma',
              style: TextStyle(fontSize: 14, color: _ink),
            ),
            children: [
              _odontogram(order.teeth),
              const SizedBox(height: 8),
              Text(
                'Dentes: ${(order.teeth.toList()..sort()).join(', ')}',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
      ],
    ],
  );

  Widget _infoRow(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ),
        Expanded(
          child: Text(
            value?.isNotEmpty == true ? value! : '—',
            style: const TextStyle(fontSize: 14, color: _ink),
          ),
        ),
      ],
    ),
  );

  Widget _odontogram(List<int> selected) {
    const rows = [
      [18, 17, 16, 15, 14, 13, 12, 11],
      [21, 22, 23, 24, 25, 26, 27, 28],
      [48, 47, 46, 45, 44, 43, 42, 41],
      [31, 32, 33, 34, 35, 36, 37, 38],
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 28) / 8;
        return Column(
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              if (rowIndex == 2) const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final tooth in rows[rowIndex])
                    Container(
                      width: width,
                      height: 40,
                      margin: const EdgeInsets.only(bottom: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected.contains(tooth)
                            ? const Color(0x26C9A227)
                            : const Color(0xFFF8F9FA),
                        border: Border.all(
                          color: selected.contains(tooth) ? _gold : _border,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$tooth',
                        style: TextStyle(
                          fontSize: 12,
                          color: selected.contains(tooth) ? _ink : _muted,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _progress(ClientOrder order) {
    final complete = order.status == 'concluido';
    final starting = ['por_receber', 'encaminhado'].contains(order.status);
    final completedSteps = order.steps.where((step) => step.completed).length;
    final calculated = order.steps.isEmpty
        ? 50
        : (completedSteps / order.steps.length * 100).round();
    final percentage = complete
        ? 100
        : starting
        ? 10
        : calculated.clamp(35, 90);
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADO ATUAL',
            style: TextStyle(fontSize: 12, color: _muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _macroLabel(order.status),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: _border,
            color: _gold,
            semanticsLabel: 'Progresso da encomenda',
            semanticsValue: '$percentage por cento',
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text(
                'Encomenda recebida',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              Spacer(),
              Text('Conclusão', style: TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conversation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Mensagens sobre esta encomenda',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      if (_messages.isEmpty)
        _panel(
          const Text(
            'Ainda não existem mensagens para a clínica.',
            style: TextStyle(fontSize: 14, color: _muted),
          ),
        )
      else
        for (final message in _messages) ...[
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${message.author} · ${message.date}',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 8),
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 14, color: _ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      const SizedBox(height: 16),
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demonstração: as mensagens não são enviadas ao laboratório.',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Escrever mensagem',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Adicionar mensagem à demonstração',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _history(ClientOrder order) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (order.events.isEmpty)
        _panel(
          const Text(
            'Ainda não há eventos para apresentar.',
            style: TextStyle(fontSize: 14, color: _muted),
          ),
        )
      else
        for (final event in order.events.reversed) ...[
          _panel(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 12, color: _gold),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 14, color: _ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${event.actor} · ${event.date}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
    ],
  );

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );

  Widget _labelChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, color: color)),
  );

  String _macroLabel(String status) => switch (status) {
    'concluido' => 'Concluído',
    'por_receber' || 'encaminhado' => 'Iniciar',
    _ => 'Processamento',
  };
}
