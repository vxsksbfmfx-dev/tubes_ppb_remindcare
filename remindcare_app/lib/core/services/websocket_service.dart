import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';

/// WebSocket client untuk RemindCare real-time.
///
/// Usage:
///   final ws = WebSocketService();
///   ws.connect(token: myToken, elderlyId: 5);
///   ws.onLogConfirmed = (data) { ... };
///   ws.dispose();
class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  bool   _connected  = false;
  bool   get connected => _connected;

  /// Callback saat log dikonfirmasi (real-time dari family/elderly lain)
  void Function(Map<String, dynamic>)? onLogConfirmed;
  /// Callback saat ada reminder baru
  void Function(Map<String, dynamic>)? onReminder;
  /// Callback error
  void Function(String)? onWsError;

  void connect({required String token, required int elderlyId}) {
    final uri = Uri.parse(AppConstants.wsUrl);
    _channel  = WebSocketChannel.connect(uri);
    _connected = true;
    notifyListeners();

    // 1. Auth
    _send({'type': 'auth', 'token': token});

    _sub = _channel!.stream.listen(
      (raw) => _handleMessage(raw, elderlyId),
      onError: (e) {
        _connected = false;
        notifyListeners();
        onWsError?.call(e.toString());
      },
      onDone: () {
        _connected = false;
        notifyListeners();
      },
    );
  }

  void _handleMessage(dynamic raw, int elderlyId) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (data['type']) {
        case 'auth_ok':
          // Subscribe ke room elderly setelah auth berhasil
          _send({'type': 'subscribe', 'elderly_id': elderlyId});
          break;
        case 'log_confirmed':
          onLogConfirmed?.call(data);
          break;
        case 'reminder':
          onReminder?.call(data);
          break;
        case 'error':
          onWsError?.call(data['message'] ?? 'WebSocket error');
          break;
        default:
          debugPrint('WS unknown type: ${data['type']}');
      }
    } catch (e) {
      debugPrint('WS parse error: $e');
    }
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('WS send error: $e');
    }
  }

  void broadcastConfirmed(int elderlyId, Map<String, dynamic> logData) {
    _send({
      'type'       : 'broadcast',
      'event'      : 'log_confirmed',
      'elderly_id' : elderlyId,
      'data'       : logData,
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
