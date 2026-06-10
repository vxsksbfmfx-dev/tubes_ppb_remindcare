class AppConstants {
  AppConstants._();

  static const String appName = 'RemindCare';

  // ── Ganti IP ini sesuai server Node.js Anda ──────────────
  // Development (emulator Android): gunakan 10.0.2.2
  // Development (device fisik)    : gunakan IP LAN, misal 192.168.1.100
  // Production                    : gunakan domain/IP VPS
  static const String _host = '10.0.2.2';  // atau '192.168.1.100' / 'api.remindcare.com'

  // ── REST API (Express — port 8000) ───────────────────────
  static const String baseUrl = 'http://$_host:8000/api';

  // ── WebSocket (ws — port 8090) ───────────────────────────
  static const String wsUrl   = 'ws://$_host:8090';

  // ── Avatar base URL ──────────────────────────────────────
  static const String storageUrl = 'http://$_host:8000';

  // ── Theme colors ─────────────────────────────────────────
  static const int primaryColor     = 0xFF1976D2;
  static const int secondaryColor   = 0xFF4CAF50;
  static const int warningColor     = 0xFFF44336;
  static const int backgroundColor  = 0xFFF5F7FA;
}
