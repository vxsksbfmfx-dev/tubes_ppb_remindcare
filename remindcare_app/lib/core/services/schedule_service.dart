import '../models/schedule_model.dart';
import 'api_client.dart';

class ScheduleService {
  final String _token;
  ScheduleService(this._token);

  /// GET /api/schedules
  Future<List<ScheduleModel>> getSchedules({int? elderlyId}) async {
    final res = await ApiClient.get(
      '/schedules',
      token: _token,
      queryParams: elderlyId != null ? {'elderly_id': '$elderlyId'} : null,
    );
    return (res['data'] as List)
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/schedules
  Future<void> createSchedule(Map<String, dynamic> data) async {
    await ApiClient.post('/schedules', data, token: _token);
  }

  /// PUT /api/schedules/:id
  Future<void> updateSchedule(int id, Map<String, dynamic> data) async {
    await ApiClient.put('/schedules/$id', data, token: _token);
  }

  /// DELETE /api/schedules/:id
  Future<void> deleteSchedule(int id) async {
    await ApiClient.delete('/schedules/$id', token: _token);
  }
}
