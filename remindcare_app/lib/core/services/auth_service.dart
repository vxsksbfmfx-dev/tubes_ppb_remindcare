import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'family',
    String? phone,
  }) async {
    final res = await ApiClient.post('/api/auth/register', {
      'name': name, 'email': email, 'password': password,
      'role': role, if (phone != null) 'phone': phone,
    });
    return res['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post('/api/auth/login', {
      'email': email, 'password': password,
    });
    return res['data'] as Map<String, dynamic>;
  }

  Future<UserModel> me(String token) async {
    final res = await ApiClient.get('/api/auth/me', token: token);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
