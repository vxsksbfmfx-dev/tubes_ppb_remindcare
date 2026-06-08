import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final String _base = AppConstants.baseUrl;
  final Map<String, String> _headers;

  ScheduleService(String token)
      : _headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

  Future<List<ScheduleModel>> getSchedules({int? elderlyId}) async {
    final uri = Uri.parse('$_base/schedules${elderlyId != null ? "?elderly_id=$elderlyId" : ""}');
    final res  = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body['data'] as List).map((e) => ScheduleModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Gagal memuat jadwal');
  }

  Future<void> createSchedule(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_base/schedules'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Gagal membuat jadwal');
    }
  }

  Future<void> deleteSchedule(int id) async {
    final res = await http.delete(Uri.parse('$_base/schedules/$id'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Gagal menghapus jadwal');
  }
}
