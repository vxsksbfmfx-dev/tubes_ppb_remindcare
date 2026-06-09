import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  static const _base = AppConstants.baseUrl;

  Future<UserModel> getMe(String token) async {
    final res = await ApiClient.get('/api/users/me', token: token);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile({
    required String token,
    required String name,
    String? phone,
    int? age,
  }) async {
    final res = await ApiClient.put('/api/users/me', {
      'name':  name,
      if (phone != null) 'phone': phone,
      if (age   != null) 'age':   age,
    }, token: token);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<UserModel> uploadAvatar({
    required String token,
    required File   file,
  }) async {
    final req = http.MultipartRequest(
      'POST', Uri.parse('$_base/api/users/me/avatar'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final body     = await streamed.stream.bytesToString();
    final json     = jsonDecode(body) as Map<String, dynamic>;

    if (streamed.statusCode >= 400) {
      throw ApiException(json['message'] ?? 'Upload gagal', streamed.statusCode);
    }
    return UserModel.fromJson(json['data'] as Map<String, dynamic>);
  }
}
