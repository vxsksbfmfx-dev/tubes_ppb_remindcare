import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  /// POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'family',
    String? phone,
  }) async {
    final res = await ApiClient.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null) 'phone': phone,
    });
    return res['data'] as Map<String, dynamic>;
  }

  /// POST /api/auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return res['data'] as Map<String, dynamic>;
  }

  /// GET /api/auth/me
  Future<UserModel> me(String token) async {
    final res = await ApiClient.get('/auth/me', token: token);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// POST /api/auth/refresh
  Future<String> refresh(String token) async {
    final res = await ApiClient.post('/auth/refresh', {}, token: token);
    return (res['data'] as Map<String, dynamic>)['token'] as String;
  }

  /// POST /api/auth/logout
  Future<void> logout(String token) async {
    await ApiClient.post('/auth/logout', {}, token: token);
  }

  /// POST /api/auth/google
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final res = await ApiClient.post('/auth/google', {'id_token': idToken});
    return res['data'] as Map<String, dynamic>;
  }
}
