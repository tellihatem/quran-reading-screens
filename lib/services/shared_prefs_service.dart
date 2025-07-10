import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  // Singleton pattern
  static final SharedPrefsService _instance = SharedPrefsService._internal();
  factory SharedPrefsService() => _instance;
  SharedPrefsService._internal();

  // Keys
  static const String _pinKey = 'app_pin_code';
  
  // Initialize SharedPreferences
  late final Future<SharedPreferences> _prefs;
  
  // Initialize the service
  void init() {
    _prefs = SharedPreferences.getInstance();
  }

  // PIN related methods
  Future<void> savePin(String pin) async {
    final prefs = await _prefs;
    await prefs.setString(_pinKey, pin);
  }

  Future<String?> getPin() async {
    final prefs = await _prefs;
    return prefs.getString(_pinKey);
  }

  Future<bool> hasPin() async {
    final prefs = await _prefs;
    return prefs.containsKey(_pinKey);
  }

  Future<void> clearPin() async {
    final prefs = await _prefs;
    await prefs.remove(_pinKey);
  }

  // Generic methods for other preferences
  Future<bool> setString(String key, String value) async {
    final prefs = await _prefs;
    return await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    final prefs = await _prefs;
    return await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _prefs;
    return prefs.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    final prefs = await _prefs;
    return await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt(key);
  }

  Future<bool> setDouble(String key, double value) async {
    final prefs = await _prefs;
    return await prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _prefs;
    return prefs.getDouble(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await _prefs;
    return await prefs.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await _prefs;
    return prefs.getStringList(key);
  }

  Future<bool> remove(String key) async {
    final prefs = await _prefs;
    return await prefs.remove(key);
  }

  Future<bool> clear() async {
    final prefs = await _prefs;
    return await prefs.clear();
  }
}

// Global instance
final sharedPrefsService = SharedPrefsService();
