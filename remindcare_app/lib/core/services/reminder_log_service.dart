import '../models/reminder_log_model.dart';
import 'api_client.dart';

class ReminderLogService {
  final String _token;
  ReminderLogService(this._token);

  /// GET /api/logs
  Future<List<ReminderLogModel>> getLogs({
    String? date,
    int? elderlyId,
  }) async {
    final res = await ApiClient.get('/logs', token: _token, queryParams: {
      if (date != null) 'date': date,
      if (elderlyId != null) 'elderly_id': '$elderlyId',
    });
    return (res['data'] as List)
        .map((e) => ReminderLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/logs/history
  Future<Map<String, dynamic>> getHistory({
    String? date,
    int? elderlyId,
    int page = 1,
  }) async {
    final res = await ApiClient.get('/logs/history', token: _token, queryParams: {
      if (date != null) 'date': date,
      if (elderlyId != null) 'elderly_id': '$elderlyId',
      'page': '$page',
    });
    return res['data'] as Map<String, dynamic>;
  }

  /// GET /api/logs/stats
  Future<Map<String, dynamic>> getStats({int? elderlyId}) async {
    final res = await ApiClient.get('/logs/stats', token: _token, queryParams: {
      if (elderlyId != null) 'elderly_id': '$elderlyId',
    });
    return res['data'] as Map<String, dynamic>;
  }

  /// POST /api/logs/:id/confirm
  Future<void> confirm(int logId) async {
    await ApiClient.post('/logs/$logId/confirm', {}, token: _token);
  }
}
