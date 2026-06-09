import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService        _authSvc    = AuthService();
  final GoogleAuthService  _googleSvc  = GoogleAuthService();
  final StorageService     _storage    = StorageService();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String?    _error;

  AuthStatus get status => _status;
  UserModel? get user   => _user;
  String?    get error  => _error;
  bool get isAuth       => _status == AuthStatus.authenticated;

  Future<void> init() async {
    final token = await _storage.getToken();
    if (token != null) {
      try {
        _user   = await _authSvc.getMe(token);
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

  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      final res = await _authSvc.login(email, password);
      await _storage.saveToken(res['token']);
      _user   = res['user'];
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

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

  Future<void> logout() async {
    await _googleSvc.signOut();
    await _storage.clearAll();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
