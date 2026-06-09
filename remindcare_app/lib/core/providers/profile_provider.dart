import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';
import '../services/user_service.dart';

enum ProfileStatus { idle, loading, success, error }

class ProfileProvider extends ChangeNotifier {
  final _svc     = UserService();
  final _session = SessionService();

  UserModel?    _user;
  ProfileStatus _status  = ProfileStatus.idle;
  String        _message = '';

  UserModel?    get user    => _user;
  ProfileStatus get status  => _status;
  String        get message => _message;
  bool          get isLoading => _status == ProfileStatus.loading;

  void setUser(UserModel u) {
    _user = u;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _status = ProfileStatus.loading;
    notifyListeners();
    try {
      final token = await _session.getToken();
      if (token == null) throw Exception('Tidak ada token');
      _user    = await _svc.getMe(token);
      _status  = ProfileStatus.success;
      await _session.saveSession(token, _user!);
    } catch (e) {
      _status  = ProfileStatus.error;
      _message = e.toString();
    }
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    int? age,
  }) async {
    _status = ProfileStatus.loading;
    notifyListeners();
    try {
      final token = await _session.getToken();
      _user   = await _svc.updateProfile(token: token!, name: name, phone: phone, age: age);
      _status = ProfileStatus.success;
      _message = 'Profil berhasil diperbarui';
      await _session.saveSession(token, _user!);
      notifyListeners();
      return true;
    } catch (e) {
      _status  = ProfileStatus.error;
      _message = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(File file) async {
    _status = ProfileStatus.loading;
    notifyListeners();
    try {
      final token = await _session.getToken();
      _user   = await _svc.uploadAvatar(token: token!, file: file);
      _status = ProfileStatus.success;
      _message = 'Avatar berhasil diperbarui';
      await _session.saveSession(token, _user!);
      notifyListeners();
      return true;
    } catch (e) {
      _status  = ProfileStatus.error;
      _message = e.toString();
      notifyListeners();
      return false;
    }
  }
}
