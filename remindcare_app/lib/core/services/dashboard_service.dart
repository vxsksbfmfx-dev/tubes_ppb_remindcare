import '../models/dashboard_model.dart';
import 'api_client.dart';

class DashboardService {
  Future<DashboardData> getDashboard(String token, {int? elderlyId}) async {
    final q   = elderlyId != null ? '?elderly_id=$elderlyId' : '';
    final res = await ApiClient.get('/api/dashboard$q', token: token);
    return DashboardData.fromJson(res['data'] as Map<String, dynamic>);
  }
}
