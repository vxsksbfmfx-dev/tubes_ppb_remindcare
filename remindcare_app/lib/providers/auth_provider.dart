import 'package:flutter/foundation.dart';
import '../core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String?    _token;
  bool       _loading = false;

  UserModel? get user    => _user;
  String?    get token   => _token;
  bool       get loading => _loading;
  bool       get isLoggedIn => _token != null && _user != null;

  void setUser(UserModel user, String token) {
    _user  = user;
    _token = token;
    notifyListeners();
  }

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void logout() {
    _user  = null;
    _token = null;
    notifyListeners();
  }
}
