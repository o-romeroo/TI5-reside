import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService._initializeLocalNotifications();
  await NotificationService._showFlutterNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Canal usado para notificações importantes',
    importance: Importance.high,
  );

  /// CORREÇÃO: Agora retorna Future<String> com o token FCM
  static Future<String> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _initializeLocalNotifications();
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // CORREÇÃO: Retorna o token ao invés de só imprimir
    final token = await _getFcmToken();

    FirebaseMessaging.onMessage.listen((message) async {
      await _showFlutterNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('App aberto pela notificação: ${message.data}');
    });

    await _handleInitialMessage();

    return token; // CORREÇÃO: Retorna o token
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notificação clicada: ${response.payload}');
      },
    );
  }

  static Future<void> _showFlutterNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Canal usado para notificações importantes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _local.show(
      message.hashCode,
      notif.title,
      notif.body,
      platformDetails,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  /// Método público para obter o FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _fcm.getToken();
      print('🔥 FCM Token obtido: ${token != null ? 'Sucesso' : 'Nulo'}');
      return token;
    } catch (e) {
      print('⚠️ Erro ao obter FCM token: $e');
      return null;
    }
  }

  /// CORREÇÃO: Agora retorna Future<String> ao invés de Future<void>
  static Future<String> _getFcmToken() async {
    try {
      final token = await _fcm.getToken();
      print('🔥 FCM Token: $token');
      return token ?? ''; // CORREÇÃO: Retorna o token ou string vazia
    } catch (e) {
      print('Erro ao obter FCM token: $e');
      return ''; // CORREÇÃO: Retorna string vazia em caso de erro
    }
  }

  static Future<void> _handleInitialMessage() async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('App iniciado pela notificação: ${initialMessage.data}');
    }
  }
}
