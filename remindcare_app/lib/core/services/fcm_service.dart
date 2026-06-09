import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

/// Background message handler — harus top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Bisa simpan ke local DB atau tampilkan notif lokal di sini
  print('[FCM Background] ${message.notification?.title}: ${message.notification?.body}');
}

class FcmService {
  final FirebaseMessaging           _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final StorageService              _storage   = StorageService();

  static const _channelId   = 'remindcare_reminder';
  static const _channelName = 'Pengingat Obat';

  /// Inisialisasi FCM — panggil di main() setelah Firebase.initializeApp()
  Future<void> init() async {
    // 1. Minta izin notifikasi (iOS wajib, Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Setup local notification channel (Android)
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS:     DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    await _local
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId, _channelName,
        description: 'Notifikasi pengingat minum obat RemindCare',
        importance: Importance.max,
      ));

    // 3. Daftarkan background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 5. Notif tap saat app di background → buka
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 6. Ambil & simpan token ke backend
    await refreshToken();

    // 7. Handle token refresh otomatis
    _messaging.onTokenRefresh.listen(_uploadToken);
  }

  /// Ambil token FCM dan kirim ke backend
  Future<void> refreshToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _storage.saveFcmToken(token);
      await _uploadToken(token);
    }
  }

  Future<void> _uploadToken(String token) async {
    final jwtToken = await _storage.getToken();
    if (jwtToken == null) return;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      ));
      await dio.post('/notifications/token', data: {'fcm_token': token});
    } catch (e) {
      print('[FCM] Gagal upload token: $e');
    }
  }

  // ── Tampilkan notif lokal saat app di foreground ───────────
  void _handleForeground(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.max,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleTap(RemoteMessage message) {
    print('[FCM] Notif di-tap: ${message.data}');
    // Navigasi sesuai message.data['type'] bisa ditambahkan di sini
  }

  void _onNotifTap(NotificationResponse response) {
    print('[FCM] Local notif di-tap: ${response.payload}');
  }
}
