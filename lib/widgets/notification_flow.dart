import 'package:flutter/material.dart';

class NotificationFlow extends StatelessWidget {
  const NotificationFlow({super.key});
  static const _steps = [
    (Icons.dns_outlined, 'Servidor', 'Evento de acesso'),
    (Icons.cloud_outlined, 'Firebase Cloud Messaging', 'Serviço de Push'),
    (
      Icons.tablet_android_outlined,
      'Tablet do Supervisor',
      'Dispositivo inscrito',
    ),
    (
      Icons.notifications_active_outlined,
      'Notificação',
      'Alerta ao supervisor',
    ),
  ];

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 580;
          final items = <Widget>[];
          for (var index = 0; index < _steps.length; index++) {
            final step = _steps[index];
            final content = Column(
              children: [
                Icon(
                  step.$1,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  step.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  step.$3,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            );
            items.add(
              horizontal
                  ? Expanded(child: content)
                  : Padding(padding: const EdgeInsets.all(8), child: content),
            );
            if (index < _steps.length - 1) {
              items.add(
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    horizontal ? Icons.arrow_forward : Icons.arrow_downward,
                    color: Colors.white38,
                    size: 18,
                  ),
                ),
              );
            }
          }
          return horizontal
              ? Row(children: items)
              : Center(child: Column(children: items));
        },
      ),
    ),
  );
}
