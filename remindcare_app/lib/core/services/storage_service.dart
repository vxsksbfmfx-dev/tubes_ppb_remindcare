import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyToken    = 'jwt_token';
  static const _keyUser     = 'user_data';
  static const _keyFcmToken = 'fcm_token';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void>   saveToken(String token) async => (await _prefs).setString(_keyToken, token);
  Future<String?> getToken()               async => (await _prefs).getString(_keyToken);

  Future<void>   saveUser(String json)    async => (await _prefs).setString(_keyUser, json);
  Future<String?> getUser()               async => (await _prefs).getString(_keyUser);

  Future<void>   saveFcmToken(String t)   async => (await _prefs).setString(_keyFcmToken, t);
  Future<String?> getFcmToken()           async => (await _prefs).getString(_keyFcmToken);

  Future<void> clearAll() async => (await _prefs).clear();
}
