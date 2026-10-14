import 'package:flutter/material.dart';
import '../models/lockmachine_alert.dart';

Color alertColor(String severity) => switch (severity) {
  'critical' => const Color(0xFFFF625D),
  'warning' => const Color(0xFFFFBC57),
  'success' => const Color(0xFF65D6A0),
  _ => const Color(0xFF82B4FF),
};
IconData alertIcon(String severity) => switch (severity) {
  'critical' => Icons.gpp_bad_outlined,
  'warning' => Icons.warning_amber_rounded,
  'success' => Icons.verified_user_outlined,
  _ => Icons.notifications_none_rounded,
};

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
    this.featured = false,
  });
  final LockMachineAlert alert;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final color = alertColor(alert.severity);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(featured ? 24 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(alertIcon(alert.severity), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert.statusLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                alert.title,
                style: TextStyle(
                  fontSize: featured ? 23 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                alert.isLocal
                    ? 'Teste educativo • Sem servidor'
                    : '${alert.machineName} • ${alert.operatorName}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (featured) ...[
                const SizedBox(height: 12),
                Text(
                  alert.reason,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    alert.formattedTimestamp,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Text(
                    alert.isLocal ? 'LOCAL' : 'PUSH • ${alert.severityLabel}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
