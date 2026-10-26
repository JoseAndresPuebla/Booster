import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';
import '../../models/user_profile.dart';
import '../../models/card_model.dart';
import '../../models/game_type.dart';
import 'storage_service.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static bool isInitialized = false;

  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: ApiConstants.supabaseUrl,
        anonKey: ApiConstants.supabaseAnonKey,
      );
      isInitialized = true;
    } catch (e) {
      debugPrint('Supabase init error (offline mode enabled): $e');
      isInitialized = false;
    }
  }

  // Profile Sync
  static Future<UserProfile?> syncOrCreateProfile(String nickname) async {
    final deviceId = StorageService.getOrCreateDeviceId();

    if (!isInitialized) {
      // Local fallback
      final local = UserProfile(
        id: deviceId,
        deviceId: deviceId,
        nickname: nickname,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      await StorageService.saveUserProfile(local);
      return local;
    }

    try {
      // Check if profile exists with this deviceId
      final response = await client
          .from('profiles')
          .select()
          .eq('device_id', deviceId)
          .maybeSingle();

      if (response != null) {
        // Update last login
        final updated = await client
            .from('profiles')
            .update({'last_login': DateTime.now().toIso8601String()})
            .eq('device_id', deviceId)
            .select()
            .single();

        final profile = UserProfile.fromJson(updated);
        await StorageService.saveUserProfile(profile);
        return profile;
      } else {
        // Create new profile
        final inserted = await client
            .from('profiles')
            .insert({
              'device_id': deviceId,
              'nickname': nickname,
              'avatar_url': 'default_avatar.png',
              'created_at': DateTime.now().toIso8601String(),
              'last_login': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        final profile = UserProfile.fromJson(inserted);
        await StorageService.saveUserProfile(profile);
        return profile;
      }
    } catch (e) {
      debugPrint('Sync profile error: $e');
      final local = UserProfile(
        id: deviceId,
        deviceId: deviceId,
        nickname: nickname,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      await StorageService.saveUserProfile(local);
      return local;
    }
  }

  // Sync Card to Remote Collection
  static Future<void> syncCardObtained(CardModel card) async {
    // 1. Always save locally first for instant response
    await StorageService.saveCardToLocalCollection(card);

    if (!isInitialized) return;

    try {
      final profile = StorageService.getUserProfile();
      if (profile == null) return;

      // Upsert card in Supabase
      await client.from('user_collection').upsert({
        'user_id': profile.id,
        'card_id': card.id,
        'game_type': card.gameType.key,
        'set_code': card.setCode,
        'card_name': card.name,
        'rarity': card.rarity.label,
        'image_url': card.imageUrl,
        'first_obtained_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,card_id');
    } catch (e) {
      debugPrint('Error syncing card to Supabase: $e');
    }
  }

  // Record pack opened
  static Future<void> recordPackOpened(GameType game) async {
    await StorageService.incrementPacksOpened(game);

    if (!isInitialized) return;

    try {
      final profile = StorageService.getUserProfile();
      if (profile == null) return;

      await client.from('daily_pack_timers').upsert({
        'user_id': profile.id,
        'game_type': game.key,
        'last_opened_at': DateTime.now().toIso8601String(),
        'packs_opened_today': StorageService.getPacksOpenedToday(game),
      }, onConflict: 'user_id,game_type');
    } catch (e) {
      debugPrint('Error syncing pack opened timer: $e');
    }
  }
}
