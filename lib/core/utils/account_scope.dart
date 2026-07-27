import 'package:shared_preferences/shared_preferences.dart';

class AccountScope {
  static const String userEmailKey = 'userEmail';
  static String _currentUserEmail = '';

  static String get currentUserEmail => _currentUserEmail;

  static bool get hasActiveUser => _currentUserEmail.isNotEmpty;

  static String get _normalizedEmail {
    final normalized = _currentUserEmail.trim().toLowerCase();
    return normalized.isEmpty ? 'guest' : normalized;
  }

  static String get scopePrefix => '$_normalizedEmail::';

  static String scopedHiveKey(String id) => '$scopePrefix$id';

  static bool matchesCurrentScopeKey(Object? key) {
    return key is String && key.startsWith(scopePrefix);
  }

  static String? unscopedId(Object? key) {
    if (key is! String || !key.startsWith(scopePrefix)) return null;
    return key.substring(scopePrefix.length);
  }

  static String scopedPrefKey(String key) => '${scopePrefix}pref::$key';

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = (prefs.getString(userEmailKey) ?? '').trim().toLowerCase();
  }

  static Future<void> setCurrentUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = email.trim().toLowerCase();
    await prefs.setString(userEmailKey, _currentUserEmail);
  }

  static Future<void> clearCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = '';
    await prefs.remove(userEmailKey);
  }
}