import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  final String _token;
  UserService(this._token);

  /// GET /api/users/me
  Future<UserModel> getMe() async {
    final res = await ApiClient.get('/users/me', token: _token);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// PUT /api/users/me
  Future<UserModel> updateMe(Map<String, dynamic> data) async {
    final res = await ApiClient.put('/users/me', data, token: _token);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// POST /api/users/me/avatar (multipart)
  Future<UserModel> uploadAvatar(String filePath) async {
    final res = await ApiClient.uploadFile('/users/me/avatar', 'avatar', filePath, token: _token);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// GET /api/users/:id
  Future<UserModel> getUser(int id) async {
    final res = await ApiClient.get('/users/$id', token: _token);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
