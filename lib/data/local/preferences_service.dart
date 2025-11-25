// lib/data/local/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _kOnboardingCompleted = 'onboarding_completed';
  static const String _kAnonymousUid = 'anonymous_uid'; // on le générera plus tard
  static const String _kCurrentColocId = 'current_coloc_id';

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    // return prefs.getBool(_kOnboardingCompleted) ?? false;
    return false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleted, true);
  }

  // Tu pourras ajouter les autres plus tard
  static Future<void> saveAnonymousUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAnonymousUid, uid);
  }

  static Future<String?> getAnonymousUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAnonymousUid);
  }

  static Future<void> saveCurrentColocId(String colocId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentColocId, colocId);
  }

  static Future<String?> getCurrentColocId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentColocId);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}