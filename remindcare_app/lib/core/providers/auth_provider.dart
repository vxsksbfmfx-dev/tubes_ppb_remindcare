import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService       _authSvc   = AuthService();
  final GoogleAuthService _googleSvc = GoogleAuthService();
  final StorageService    _storage   = StorageService();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String?    _error;

  AuthStatus get status  => _status;
  UserModel? get user    => _user;
  String?    get error   => _error;
  bool get isAuth        => _status == AuthStatus.authenticated;
  bool get isLoggedIn    => isAuth;

  // ── Dipanggil saat app start ──────────────────────────────
  Future<void> init() async {
    final token = await _storage.getToken();
    if (token != null) {
      try {
        _user   = await _authSvc.me(token);   // me(), bukan getMe()
        _status = AuthStatus.authenticated;
      } catch (_) {
        await _storage.clearAll();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Email/password login ──────────────────────────────────
  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      // login() pakai named params
      final data  = await _authSvc.login(email: email, password: password);
      final token = data['token'] as String;
      await _storage.saveToken(token);
      _user   = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Google login ──────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _error = null;
    try {
      final res = await _googleSvc.signInWithGoogle();
      await _storage.saveToken(res['token'] as String);
      _user   = res['user'] as UserModel;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'family',
    String? phone,
  }) async {
    _error = null;
    try {
      final data  = await _authSvc.register(
        name: name, email: email, password: password,
        role: role, phone: phone,
      );
      final token = data['token'] as String;
      await _storage.saveToken(token);
      _user   = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    await _googleSvc.signOut();
    await _storage.clearAll();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}