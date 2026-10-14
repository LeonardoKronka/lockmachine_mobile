import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lockmachine_alert.dart';
import '../services/notification_service.dart';
import '../widgets/alert_card.dart';
import '../widgets/notification_flow.dart';
import '../widgets/status_card.dart';
import 'alert_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.service});
  final NotificationService service;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _testing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.service.refreshPermission();
  }

  void _details(LockMachineAlert alert) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AlertDetailScreen(alert: alert)),
  );
  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _testLocal() async {
    setState(() => _testing = true);
    try {
      await widget.service.testLocalNotification();
      _message('Notificação local criada no Android.');
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _copyToken() async {
    final token = widget.service.token;
    if (token == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: token));
      _message('FCM Token copiado.');
    } catch (error) {
      _message('Não foi possível copiar o token.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.service,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 950;
            final alerts = widget.service.alerts;
            final mainColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Último alerta', Icons.notifications_active_outlined),
                if (alerts.isEmpty)
                  _empty(
                    'Nenhum alerta recebido ainda.',
                    'Os eventos recebidos pelo dispositivo aparecerão aqui.',
                  )
                else
                  AlertCard(
                    alert: alerts.first,
                    featured: true,
                    onTap: () => _details(alerts.first),
                  ),
                const SizedBox(height: 28),
                _heading(
                  'Histórico de Alertas',
                  Icons.history,
                  trailing: '${alerts.length} eventos',
                ),
                if (alerts.isEmpty)
                  _empty(
                    'Histórico vazio',
                    'Os alertas desta execução serão listados do mais recente ao mais antigo.',
                  )
                else
                  ...alerts.map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AlertCard(
                        alert: alert,
                        onTap: () => _details(alert),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Histórico em memória • Reiniciado ao encerrar o aplicativo',
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ],
            );
            final sideColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Dispositivo', Icons.tablet_android_outlined),
                _deviceCard(),
                const SizedBox(height: 28),
                _heading('Local × Push', Icons.school_outlined),
                _educationCard(),
              ],
            );
            return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth < 600 ? 18 : 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(),
                      const SizedBox(height: 28),
                      StatusCard(
                        connected: widget.service.connected,
                        initializing: widget.service.initializing,
                        message: widget.service.connectionError,
                        onRetry: widget.service.initialize,
                      ),
                      const SizedBox(height: 28),
                      _heading(
                        'Como a Push chega ao supervisor?',
                        Icons.route_outlined,
                      ),
                      const NotificationFlow(),
                      const SizedBox(height: 28),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: mainColumn),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: sideColumn),
                          ],
                        )
                      else ...[
                        mainColumn,
                        const SizedBox(height: 28),
                        sideColumn,
                      ],
                      const SizedBox(height: 32),
                      const Text(
                        'LOCKMACHINE MOBILE  /  Controle de acesso industrial',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.lock_outline_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      const SizedBox(width: 16),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOCKMACHINE',
              style: TextStyle(
                fontSize: 23,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Central de Alertas',
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _heading(String title, IconData icon, {String? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
      ],
    ),
  );

  Widget _empty(String title, String description) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 34,
            color: Colors.white38,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, height: 1.5),
          ),
        ],
      ),
    ),
  );

  Widget _deviceCard() {
    final service = widget.service;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PERMISSÃO DE NOTIFICAÇÕES',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              service.permissionLabel,
              style: TextStyle(
                color: service.permissionGranted
                    ? const Color(0xFF65D6A0)
                    : const Color(0xFFFFBC57),
              ),
            ),
            if (!service.permissionGranted && service.localReady) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () async {
                  try {
                    await service.requestPermission();
                  } catch (error) {
                    _message('Não foi possível solicitar a permissão.');
                  }
                },
                child: const Text('Solicitar permissão'),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(),
            ),
            const Text(
              'FCM TOKEN',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111216),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                service.token ??
                    'Disponível após configurar e conectar o Firebase.',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: service.token == null ? null : _copyToken,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar token'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(),
            ),
            const Text(
              'TÓPICO',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const SelectableText(
              NotificationService.topic,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              service.subscribed
                  ? 'Dispositivo inscrito automaticamente'
                  : 'Inscrição pendente',
              style: TextStyle(
                color: service.subscribed
                    ? const Color(0xFF65D6A0)
                    : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _educationCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Notificação Local',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'É criada pelo próprio aplicativo e não precisa de um servidor.',
            style: TextStyle(color: Colors.white60, height: 1.5),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          const Text(
            'Push Notification',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'É enviada por um servidor através de um serviço de Push, como o Firebase Cloud Messaging.',
            style: TextStyle(color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: widget.service.localReady && !_testing
                ? _testLocal
                : null,
            icon: const Icon(Icons.notifications_active_outlined, size: 20),
            label: Text(
              _testing ? 'Criando notificação…' : 'Testar notificação local',
            ),
          ),
          if (widget.service.localError != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.service.localError!,
              style: const TextStyle(color: Color(0xFFFFBC57)),
            ),
          ],
        ],
      ),
    ),
  );
}
