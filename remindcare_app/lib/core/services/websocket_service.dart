import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';

/// WebSocketService — Node.js ws server (port 8090)
///
/// Protocol sama seperti PHP Ratchet (backward compatible):
///   Kirim : { "type":"auth",      "token":"..." }
///   Kirim : { "type":"subscribe", "elderly_id": 5 }
///   Terima: { "type":"auth_ok",   "user_id": 1 }
///   Terima: { "type":"subscribed","elderly_id": 5 }
///   Terima: { "type":"log_confirmed", "data":{...} }
///   Terima: { "type":"reminder",      "data":{...} }
class WebSocketService {
  static const String _wsUrl = AppConstants.wsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _connected = false;

  final StreamController<Map<String, dynamic>> _eventCtrl =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _eventCtrl.stream;
  bool get isConnected => _connected;

  /// Hubungkan ke WebSocket Node.js
  Future<void> connect(String token, {int? elderlyId}) async {
    if (_connected) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _connected = true;

      _sub = _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _eventCtrl.add(data);
          } catch (_) {}
        },
        onDone: () {
          _connected = false;
          _eventCtrl.add({'type': 'disconnected'});
        },
        onError: (e) {
          _connected = false;
          _eventCtrl.add({'type': 'error', 'message': e.toString()});
        },
      );

      // Autentikasi
      _send({'type': 'auth', 'token': token});

      // Tunggu auth_ok lalu subscribe
      await for (final event in _eventCtrl.stream) {
        if (event['type'] == 'auth_ok') {
          subscribe(elderlyId ?? (event['user_id'] as int));
          break;
        }
        if (event['type'] == 'error') break;
      }
    } catch (e) {
      _connected = false;
      _eventCtrl.add({'type': 'error', 'message': e.toString()});
    }
  }

  /// Subscribe ke room elderly
  void subscribe(int elderlyId) {
    _send({'type': 'subscribe', 'elderly_id': elderlyId});
  }

  /// Broadcast event (dari keluarga ke elderly atau sebaliknya)
  void broadcast(int elderlyId, String event, Map<String, dynamic> data) {
    _send({'type': 'broadcast', 'elderly_id': elderlyId, 'event': event, 'data': data});
  }

  void _send(Map<String, dynamic> payload) {
    if (_connected && _channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void disconnect() {
    _sub?.cancel();
    _channel?.sink.close();
    _connected = false;
  }

  void dispose() {
    disconnect();
    _eventCtrl.close();
  }
}
