import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionService {
  static const _keyToken = 'auth_token';
  static const _keyUser  = 'auth_user';

  // ── Simpan sesi ──────────────────────────────────────────
  Future<void> saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  // ── Ambil token ──────────────────────────────────────────
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // ── Ambil user ───────────────────────────────────────────
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Cek apakah sudah login ───────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Hapus sesi (logout) ──────────────────────────────────
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  // ── Update token saja (setelah refresh) ─────────────────
  Future<void> updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, newToken);
  }

  // ── Simpan preferensi tambahan ───────────────────────────
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
