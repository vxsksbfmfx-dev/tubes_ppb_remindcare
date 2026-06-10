import 'api_client.dart';

class NotificationService {
  final String _token;
  NotificationService(this._token);

  /// POST /api/fcm-token
  Future<void> saveFcmToken(String fcmToken) async {
    await ApiClient.post('/fcm-token', {'fcm_token': fcmToken}, token: _token);
  }

  /// POST /api/notifications/test
  Future<void> sendTest() async {
    await ApiClient.post('/notifications/test', {}, token: _token);
  }

  /// POST /api/notifications/remind
  Future<void> sendRemind(int elderlyId, int logId) async {
    await ApiClient.post('/notifications/remind', {
      'elderly_id': elderlyId,
      'log_id': logId,
    }, token: _token);
  }
}
