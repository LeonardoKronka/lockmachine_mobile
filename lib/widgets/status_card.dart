import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.connected,
    required this.initializing,
    required this.message,
    required this.onRetry,
  });
  final bool connected;
  final bool initializing;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final color = connected ? const Color(0xFF65D6A0) : const Color(0xFFFFBC57);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (initializing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.circle, size: 12, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    initializing
                        ? 'Conectando dispositivo…'
                        : connected
                        ? 'Sistema conectado'
                        : 'Sistema aguardando conexão',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Firebase Cloud Messaging',
              style: TextStyle(color: Colors.white60),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
            if (!connected && !initializing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar conectar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
