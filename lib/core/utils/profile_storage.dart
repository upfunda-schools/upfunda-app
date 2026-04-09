import 'package:shared_preferences/shared_preferences.dart';

/// Persists the selected student profile ID across app restarts and browser
/// refreshes (equivalent to the cookie-based profileId in the web frontend).
class ProfileStorage {
  static const _key = 'selected_profile_id';

  // In-memory cache so synchronous reads remain fast.
  static String? _profileId;

  static String? get profileId => _profileId;

  static set profileId(String? value) {
    _profileId = value;
    _persist(value);
  }

  /// Load persisted value on app startup — call once from main() before runApp.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _profileId = prefs.getString(_key);
  }

  static Future<void> _persist(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value);
    }
  }
}
