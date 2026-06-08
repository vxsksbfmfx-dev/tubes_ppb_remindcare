import 'package:flutter/foundation.dart';
import '../core/services/websocket_service.dart';

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _ws = WebSocketService();

  bool get connected => _ws.connected;

  void connect(String token, int elderlyId) {
    _ws.connect(token: token, elderlyId: elderlyId);
    _ws.addListener(() => notifyListeners());
  }

  void onLogConfirmed(void Function(Map<String, dynamic>) cb) {
    _ws.onLogConfirmed = cb;
  }

  void onReminder(void Function(Map<String, dynamic>) cb) {
    _ws.onReminder = cb;
  }

  void broadcastConfirmed(int elderlyId, Map<String, dynamic> data) {
    _ws.broadcastConfirmed(elderlyId, data);
  }

  @override
  void dispose() {
    _ws.dispose();
    super.dispose();
  }
}
