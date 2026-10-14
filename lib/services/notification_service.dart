import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/lockmachine_alert.dart';

const _backgroundPortName = 'lockmachine_alert_receiver';

/// Android displays notification + data messages itself in the background.
/// Do not display a second local notification here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  IsolateNameServer.lookupPortByName(
    _backgroundPortName,
  )?.send(NotificationService.messageData(message));
}

class NotificationService extends ChangeNotifier {
  static const topic = 'lockmachine-supervisores';
  static const channel = AndroidNotificationChannel(
    'lockmachine_alerts',
    'Alertas LockMachine',
    description: 'Eventos de acesso e qualificação de máquinas industriais.',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();
  final _alerts = <LockMachineAlert>[];
  final _subscriptions = <StreamSubscription<dynamic>>[];
  ReceivePort? _backgroundPort;
  bool _disposed = false;
  bool _localReady = false;
  bool _listenersReady = false;
  bool _firebaseReady = false;
  int _notificationId = 0;

  bool initializing = false;
  bool subscribed = false;
  String? token;
  String? connectionError;
  String? localError;
  String permissionLabel = 'Não verificada';
  bool permissionGranted = false;
  void Function(LockMachineAlert alert)? onOpenAlert;

  List<LockMachineAlert> get alerts => List.unmodifiable(_alerts);
  bool get connected => _firebaseReady && subscribed && token != null;
  bool get localReady => _localReady;
  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static Map<String, dynamic> messageData(RemoteMessage message) => {
    ...message.data,
    if (!message.data.containsKey('id') && message.messageId != null)
      'id': message.messageId,
    if (!message.data.containsKey('title') &&
        message.notification?.title != null)
      'title': message.notification!.title,
    if (!message.data.containsKey('reason') &&
        message.notification?.body != null)
      'reason': message.notification!.body,
    if (!message.data.containsKey('timestamp') && message.sentTime != null)
      'timestamp': message.sentTime!.toIso8601String(),
  };

  Future<void> initialize() async {
    if (initializing || _disposed) return;
    initializing = true;
    connectionError = null;
    _notify();
    if (!isAndroid) {
      connectionError =
          'As notificações desta demonstração são destinadas ao Android.';
      initializing = false;
      _notify();
      return;
    }
    try {
      await _initializeLocal();
    } catch (error) {
      localError = 'Não foi possível preparar notificações locais: $error';
    }
    try {
      // Native Android resources come from android/app/google-services.json.
      // Keep the app compilable before any real Firebase configuration exists.
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _firebaseReady = true;
      _registerListeners();
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _receive(initial, openDetails: true);
      await requestPermission();
      token = await FirebaseMessaging.instance.getToken();
      if (token == null) throw StateError('O Firebase não retornou um token.');
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      subscribed = true;
    } catch (error) {
      subscribed = false;
      connectionError = _firebaseReady
          ? 'Não foi possível registrar o dispositivo no FCM. Verifique a internet e tente novamente.'
          : 'Firebase ainda não configurado. Coloque o google-services.json em android/app e reinstale o aplicativo.';
      debugPrint('Falha ao inicializar FCM: $error');
      if (!_firebaseReady && _localReady) {
        try {
          await requestPermission();
        } catch (error) {
          localError = 'Não foi possível solicitar permissão: $error';
        }
      }
    } finally {
      initializing = false;
      _notify();
    }
  }

  Future<void> _initializeLocal() async {
    if (_localReady) return;
    final initialized = await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_lockmachine'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _openPayload(response.payload),
    );
    if (initialized == false) {
      throw StateError('Plugin de notificações indisponível.');
    }
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _localReady = true;
    localError = null;
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _openPayload(launch?.notificationResponse?.payload);
    }
  }

  void _registerListeners() {
    if (_listenersReady) return;
    _listenersReady = true;
    _backgroundPort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      _backgroundPort!.sendPort,
      _backgroundPortName,
    );
    _backgroundPort!.listen((data) {
      if (data is Map) {
        recordAlert(LockMachineAlert.fromMap(Map<String, dynamic>.from(data)));
      }
    });
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((message) {
        final alert = _receive(message);
        if (_localReady) unawaited(_showForeground(alert));
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _receive(message, openDetails: true);
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) async {
          token = newToken;
          subscribed = false;
          _notify();
          try {
            await FirebaseMessaging.instance.subscribeToTopic(topic);
            subscribed = true;
            connectionError = null;
          } catch (error) {
            connectionError =
                'Falha ao renovar inscrição no tópico. Tente conectar novamente.';
          }
          _notify();
        },
        onError: (Object error) {
          connectionError = 'Falha ao atualizar o token do dispositivo.';
          _notify();
        },
      ),
    );
  }

  LockMachineAlert _receive(RemoteMessage message, {bool openDetails = false}) {
    final alert = LockMachineAlert.fromMap(messageData(message));
    recordAlert(alert, openDetails: openDetails);
    return alert;
  }

  void recordAlert(LockMachineAlert alert, {bool openDetails = false}) {
    if (_disposed) return;
    if (!_alerts.any((existing) => existing.id == alert.id)) {
      _alerts.add(alert);
      _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _notify();
    }
    if (openDetails) onOpenAlert?.call(alert);
  }

  void _openPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        recordAlert(LockMachineAlert.fromMap(decoded), openDetails: true);
      }
    } catch (error) {
      localError = 'Não foi possível ler os detalhes desta notificação.';
      _notify();
    }
  }

  Future<void> requestPermission() async {
    if (_firebaseReady) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } else if (_localReady) {
      permissionGranted =
          await _local
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    await refreshPermission();
  }

  Future<void> refreshPermission() async {
    if (!isAndroid || !_localReady) return;
    try {
      permissionGranted =
          await _local
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
      permissionLabel = permissionGranted
          ? 'Permitidas'
          : 'Bloqueadas nas configurações do Android';
    } catch (error) {
      permissionLabel = 'Não foi possível verificar a permissão';
    }
    _notify();
  }

  Future<void> _show(LockMachineAlert alert) async {
    await _local.show(
      id: ++_notificationId,
      title: alert.title,
      body: alert.reason,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_stat_lockmachine',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(alert.reason),
        ),
      ),
      payload: jsonEncode(alert.toMap()),
    );
  }

  Future<void> _showForeground(LockMachineAlert alert) async {
    try {
      await _show(alert);
    } catch (error) {
      localError =
          'O alerta foi recebido, mas a notificação visível falhou: $error';
      _notify();
    }
  }

  Future<void> testLocalNotification() async {
    if (!_localReady) {
      throw StateError('Notificações locais ainda não disponíveis.');
    }
    await requestPermission();
    if (!permissionGranted) {
      throw StateError('Permita notificações nas configurações do Android.');
    }
    final alert = LockMachineAlert.fromMap({
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'type': 'local_demo',
      'title': 'Demonstração de notificação local',
      'reason':
          'Criada pelo próprio aplicativo, sem servidor e sem Firebase Cloud Messaging.',
      'severity': 'info',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    await _show(alert);
    recordAlert(alert);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    if (_backgroundPort != null) {
      IsolateNameServer.removePortNameMapping(_backgroundPortName);
      _backgroundPort!.close();
    }
    super.dispose();
  }
}
