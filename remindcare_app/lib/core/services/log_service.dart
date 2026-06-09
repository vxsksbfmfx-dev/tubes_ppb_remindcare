import '../models/reminder_log_model.dart';
import '../models/stats_model.dart';
import 'api_client.dart';

class LogService {
  Future<List<ReminderLogModel>> getToday(String token, {int? elderlyId}) async {
    final q   = elderlyId != null ? '?elderly_id=$elderlyId' : '';
    final res = await ApiClient.get('/api/logs$q', token: token);
    final list = res['data'] as List;
    return list.map((e) => ReminderLogModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getHistory(String token, {
    int? elderlyId, String? date, int page = 1,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (elderlyId != null) 'elderly_id': elderlyId.toString(),
      if (date != null && date.isNotEmpty) 'date': date,
    };
    final q = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final res = await ApiClient.get('/api/logs/history?$q', token: token);
    final data = res['data'] as Map<String, dynamic>;
    return {
      'items': (data['items'] as List)
          .map((e) => ReminderLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'total':        data['total']        as int,
      'current_page': data['current_page'] as int,
      'last_page':    data['last_page']    as int,
    };
  }

  Future<Map<String, dynamic>> getStats(String token, {int? elderlyId}) async {
    final q   = elderlyId != null ? '?elderly_id=$elderlyId' : '';
    final res = await ApiClient.get('/api/logs/stats$q', token: token);
    final data = res['data'] as Map<String, dynamic>;
    return {
      'weekly': (data['weekly'] as List)
          .map((e) => DailyStatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'monthly': MonthlySummaryModel.fromJson(
          data['monthly'] as Map<String, dynamic>),
    };
  }

  Future<ReminderLogModel> confirm(String token, int logId) async {
    final res = await ApiClient.post('/api/logs/$logId/confirm', {}, token: token);
    return ReminderLogModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
