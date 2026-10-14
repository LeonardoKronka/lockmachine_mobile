class LockMachineAlert {
  const LockMachineAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.operatorName,
    required this.operatorId,
    required this.machineName,
    required this.machineId,
    required this.reason,
    required this.timestamp,
    required this.severity,
  });

  final String id;
  final String type;
  final String title;
  final String operatorName;
  final String operatorId;
  final String machineName;
  final String machineId;
  final String reason;
  final DateTime timestamp;
  final String severity;

  factory LockMachineAlert.fromMap(Map<String, dynamic> map) {
    String field(String key, String fallback) {
      final value = map[key]?.toString().trim();
      return value == null || value.isEmpty ? fallback : value;
    }

    final rawTime = map['timestamp'];
    final time = rawTime is DateTime
        ? rawTime
        : DateTime.tryParse(rawTime?.toString() ?? '') ?? DateTime.now();
    final type = field('type', 'unknown');
    final defaultSeverity = switch (type) {
      'unauthorized_access' || 'blocked_machine' => 'critical',
      'expired_qualification' || 'qualification_expiring' => 'warning',
      'authorized_access' => 'success',
      _ => 'info',
    };
    final severity = field('severity', defaultSeverity);
    return LockMachineAlert(
      id: field('id', 'received-${DateTime.now().microsecondsSinceEpoch}'),
      type: type,
      title: field('title', 'Alerta LockMachine'),
      operatorName: field('operatorName', 'Não informado'),
      operatorId: field('operatorId', 'Não informado'),
      machineName: field('machineName', 'Não informada'),
      machineId: field('machineId', 'Não informado'),
      reason: field('reason', 'Motivo não informado.'),
      timestamp: time,
      severity:
          const {'critical', 'warning', 'info', 'success'}.contains(severity)
          ? severity
          : defaultSeverity,
    );
  }

  bool get isLocal => type == 'local_demo';
  String get statusLabel => switch (type) {
    'unauthorized_access' => 'ACESSO NEGADO',
    'expired_qualification' => 'QUALIFICAÇÃO VENCIDA',
    'blocked_machine' => 'MÁQUINA BLOQUEADA',
    'qualification_expiring' => 'TREINAMENTO A VENCER',
    'authorized_access' => 'ACESSO AUTORIZADO',
    'local_demo' => 'DEMONSTRAÇÃO LOCAL',
    _ => 'ALERTA RECEBIDO',
  };
  String get severityLabel => switch (severity) {
    'critical' => 'Crítico',
    'warning' => 'Atenção',
    'success' => 'Autorizado',
    _ => 'Informação',
  };

  String get formattedTimestamp {
    final local = timestamp.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} - '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Map<String, String> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'operatorName': operatorName,
    'operatorId': operatorId,
    'machineName': machineName,
    'machineId': machineId,
    'reason': reason,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'severity': severity,
  };
}
