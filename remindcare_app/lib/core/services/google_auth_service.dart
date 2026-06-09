import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class GoogleAuthService {
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  Future<Map<String, dynamic>> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Login dibatalkan');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Gagal mendapatkan ID token dari Google');

    final res = await _dio.post('/auth/google', data: {'id_token': idToken});

    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Login Google gagal');
    }

    return {
      'user':  UserModel.fromJson(res.data['data']['user']),
      'token': res.data['data']['token'] as String,
    };
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
