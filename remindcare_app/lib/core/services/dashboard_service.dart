import 'api_client.dart';

class DashboardService {
  final String _token;
  DashboardService(this._token);

  /// GET /api/dashboard
  Future<Map<String, dynamic>> getDashboard({int? elderlyId}) async {
    final res = await ApiClient.get(
      '/dashboard',
      token: _token,
      queryParams: elderlyId != null ? {'elderly_id': '$elderlyId'} : null,
    );
    return res['data'] as Map<String, dynamic>;
  }
}
