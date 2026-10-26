import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_profile.dart';
import '../../models/card_model.dart';
import '../../models/game_type.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static const String _keyDeviceId = 'device_id';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyCollectionPrefix = 'collection_';
  static const String _keyTimerPrefix = 'timer_';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Device ID Management
  static String getOrCreateDeviceId() {
    String? id = _prefs.getString(_keyDeviceId);
    if (id == null) {
      id = const Uuid().v4();
      _prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  // Profile Management
  static Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setString(_keyUserProfile, jsonEncode(profile.toJson()));
  }

  static UserProfile? getUserProfile() {
    final raw = _prefs.getString(_keyUserProfile);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Admin / Tester bypass check
  static bool isAdminUser() {
    final profile = getUserProfile();
    if (profile == null) return false;
    final name = profile.nickname.trim().toLowerCase();
    return name == 'admin01' || name == 'admin' || name == 'tester';
  }

  // Daily Timer: How many packs opened today for a given game
  static int getPacksOpenedToday(GameType game) {
    final todayStr = _getTodayDateString();
    return _prefs.getInt('$_keyTimerPrefix${game.key}_$todayStr') ?? 0;
  }

  static Future<void> incrementPacksOpened(GameType game) async {
    final todayStr = _getTodayDateString();
    final current = getPacksOpenedToday(game);
    await _prefs.setInt('$_keyTimerPrefix${game.key}_$todayStr', current + 1);
  }

  static int getRemainingPacksToday(GameType game, int maxDaily) {
    if (isAdminUser()) {
      return 999; // Unlimited boosters for testing!
    }
    final opened = getPacksOpenedToday(game);
    final remaining = maxDaily - opened;
    return remaining > 0 ? remaining : 0;
  }

  static Duration getTimeUntilNextDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Local Collection Cache
  static Future<void> saveCardToLocalCollection(CardModel card) async {
    final key = '$_keyCollectionPrefix${card.gameType.key}';
    final current = getLocalCollection(card.gameType);
    
    // Check if card already exists, update count
    int index = current.indexWhere((c) => c['card_id'] == card.id);
    if (index >= 0) {
      current[index]['count'] = (current[index]['count'] as int? ?? 1) + 1;
    } else {
      current.add({
        'card_id': card.id,
        'card': card.toJson(),
        'count': 1,
        'first_obtained_at': DateTime.now().toIso8601String(),
        'is_favorite': false,
      });
    }

    await _prefs.setString(key, jsonEncode(current));
  }

  static List<Map<String, dynamic>> getLocalCollection(GameType game) {
    final key = '$_keyCollectionPrefix${game.key}';
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static int getTotalCardsCollected(GameType game) {
    return getLocalCollection(game).length;
  }
}
