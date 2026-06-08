import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/reminder_log_model.dart';

class ReminderLogService {
  final String _base = AppConstants.baseUrl;
  final Map<String, String> _headers;

  ReminderLogService(String token)
      : _headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

  Future<List<ReminderLogModel>> getLogs({String? date, int? elderlyId}) async {
    final params = {
      if (date != null) 'date': date,
      if (elderlyId != null) 'elderly_id': elderlyId.toString(),
    };
    final uri  = Uri.parse('$_base/logs').replace(queryParameters: params);
    final res  = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body['data'] as List).map((e) => ReminderLogModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Gagal memuat log');
  }

  Future<void> confirm(int logId) async {
    final res = await http.post(Uri.parse('$_base/logs/$logId/confirm'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Gagal konfirmasi');
  }

  Future<List<Map<String, dynamic>>> weeklyReport({int? elderlyId}) async {
    final uri = Uri.parse('$_base/logs/weekly-report${elderlyId != null ? "?elderly_id=$elderlyId" : ""}');
    final res  = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(body['data']);
    throw Exception('Gagal memuat laporan');
  }
}
