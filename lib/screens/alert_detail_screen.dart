import 'package:flutter/material.dart';
import '../models/lockmachine_alert.dart';
import '../widgets/alert_card.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alert});
  final LockMachineAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = alertColor(alert.severity);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DETALHES DO ALERTA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(alertIcon(alert.severity), color: color, size: 44),
                        const SizedBox(height: 20),
                        Text(
                          alert.statusLabel,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(alert.title, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 10),
                        Text(
                          alert.isLocal
                              ? 'Notificação local • Criada neste dispositivo'
                              : 'Push Notification • Firebase Cloud Messaging',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _field('Status', alert.statusLabel),
                        _field('Máquina', alert.machineName),
                        _field('ID da máquina', alert.machineId),
                        _field('Operador', alert.operatorName),
                        _field('ID do operador', alert.operatorId),
                        _field('Motivo', alert.reason),
                        _field('Data e hora', alert.formattedTimestamp),
                        _field('Severidade', alert.severityLabel),
                        _field('ID do evento', alert.id),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 6),
        SelectableText(
          value,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    ),
  );
}
