import 'package:shared_preferences/shared_preferences.dart';

class UserCacheService {
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _photoKey = 'user_photo';
  static const _usernameKey = 'user_username';
  static const _gameKey = 'user_game';
  static const _gameIdKey = 'user_game_id';

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
      'photo': prefs.getString(_photoKey) ?? '',
      'username': prefs.getString(_usernameKey) ?? '',
      'game': prefs.getString(_gameKey) ?? '',
      'gameId': prefs.getString(_gameIdKey) ?? '',
    };
  }

  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, (data['name'] as String?) ?? '');
    await prefs.setString(_emailKey, (data['email'] as String?) ?? '');
    await prefs.setString(_photoKey, (data['photo'] as String?) ?? '');
    await prefs.setString(_usernameKey, (data['username'] as String?) ?? '');
    await prefs.setString(_gameKey, (data['game'] as String?) ?? '');
    await prefs.setString(_gameIdKey, (data['gameId'] as String?) ?? '');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_photoKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_gameKey);
    await prefs.remove(_gameIdKey);
  }
}
