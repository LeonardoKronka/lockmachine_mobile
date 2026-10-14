import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification/main.dart';
import 'package:push_notification/models/lockmachine_alert.dart';
import 'package:push_notification/screens/alert_detail_screen.dart';
import 'package:push_notification/services/notification_service.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(800, 1280),
    const Size(1280, 800),
  ]) {
    testWidgets('Home is responsive at $size without Firebase credentials', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = NotificationService();
      await tester.pumpWidget(
        LockMachineApp(service: service, initialize: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('LOCKMACHINE'), findsOneWidget);
      expect(find.text('Nenhum alerta recebido ainda.'), findsOneWidget);
      await tester.ensureVisible(find.text('Testar notificação local'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    });
  }

  testWidgets(
    'A notification tap opens real payload details, even for a known event',
    (tester) async {
      final service = NotificationService();
      await tester.pumpWidget(
        LockMachineApp(service: service, initialize: false),
      );
      final alert = LockMachineAlert.fromMap({
        'id': 'event-42',
        'type': 'unauthorized_access',
        'title': 'Acesso não autorizado',
        'machineName': 'Prensa Hidráulica 02',
        'machineId': 'MAQ-02',
        'operatorName': 'Carlos Henrique',
        'operatorId': 'OP-042',
        'reason': 'Sem qualificação para esta máquina.',
      });
      service.recordAlert(alert);
      await tester.pumpAndSettle();
      service.recordAlert(alert, openDetails: true);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDetailScreen), findsOneWidget);
      expect(find.text('Prensa Hidráulica 02'), findsOneWidget);
      expect(find.text('Carlos Henrique'), findsOneWidget);
      expect(find.text('Sem qualificação para esta máquina.'), findsOneWidget);
      expect(service.alerts.length, 1);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Central de Alertas'), findsOneWidget);
      await tester.ensureVisible(find.text('Acesso não autorizado').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Acesso não autorizado').first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    },
  );
}
