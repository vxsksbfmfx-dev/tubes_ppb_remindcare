import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override String toString() => message;
}

class ApiClient {
  static const _base = AppConstants.baseUrl;

  static Future<Map<String, dynamic>> get(
      String path, {String? token}) async {
    final res = await http.get(
      Uri.parse('$_base$path'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body, {String? token}) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body, {String? token}) async {
    final res = await http.put(
      Uri.parse('$_base$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> delete(
      String path, {String? token}) async {
    final res = await http.delete(
      Uri.parse('$_base$path'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));
    return _parse(res);
  }

  static Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(body['message'] ?? 'Terjadi kesalahan', res.statusCode);
    }
    return body;
  }
}
