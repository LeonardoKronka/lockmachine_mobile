import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification/models/lockmachine_alert.dart';
import 'package:push_notification/services/notification_service.dart';

void main() {
  test('Missing and malformed payload fields are safe', () {
    final empty = LockMachineAlert.fromMap({});
    expect(empty.operatorName, 'Não informado');
    expect(empty.severity, 'info');
    expect(empty.id, isNotEmpty);
    final invalid = LockMachineAlert.fromMap({
      'timestamp': 'invalid',
      'title': ' ',
      'severity': 'invalid',
      'operatorId': 42,
      'type': 'unauthorized_access',
    });
    expect(invalid.title, 'Alerta LockMachine');
    expect(invalid.operatorId, '42');
    expect(invalid.severity, 'critical');
  });

  test('Server payload survives a local notification round trip', () {
    final data = <String, dynamic>{
      'id': 'event-42',
      'type': 'unauthorized_access',
      'title': 'Acesso não autorizado',
      'operatorName': 'Carlos Henrique',
      'operatorId': 'OP-042',
      'machineName': 'Prensa Hidráulica 02',
      'machineId': 'MAQ-02',
      'reason': 'Sem qualificação.',
      'timestamp': '2026-10-07T16:30:00.000Z',
      'severity': 'critical',
    };
    final alert = LockMachineAlert.fromMap(data);
    final restored = LockMachineAlert.fromMap(alert.toMap());
    expect(restored.toMap(), alert.toMap());
    expect(restored.timestamp.toUtc(), DateTime.utc(2026, 10, 7, 16, 30));
    expect(restored.statusLabel, 'ACESSO NEGADO');
  });

  test('Notification-only FCM messages have useful fallback fields', () {
    const message = RemoteMessage(
      messageId: 'fcm-42',
      notification: RemoteNotification(
        title: 'Alerta real',
        body: 'Motivo real',
      ),
    );
    final alert = LockMachineAlert.fromMap(
      NotificationService.messageData(message),
    );
    expect(alert.id, 'fcm-42');
    expect(alert.title, 'Alerta real');
    expect(alert.reason, 'Motivo real');
  });

  test('History sorts events and notification taps never duplicate them', () {
    final service = NotificationService();
    addTearDown(service.dispose);
    final old = LockMachineAlert.fromMap({
      'id': 'old',
      'timestamp': '2026-10-07T13:00:00Z',
    });
    final latest = LockMachineAlert.fromMap({
      'id': 'latest',
      'timestamp': '2026-10-07T14:00:00Z',
    });
    LockMachineAlert? opened;
    service.onOpenAlert = (alert) => opened = alert;
    service.recordAlert(latest);
    service.recordAlert(old);
    service.recordAlert(latest, openDetails: true);
    expect(service.alerts.map((alert) => alert.id), ['latest', 'old']);
    expect(opened?.id, 'latest');
    expect(() => service.alerts.clear(), throwsUnsupportedError);
  });
}
