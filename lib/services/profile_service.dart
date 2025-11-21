import 'package:shared_preferences/shared_preferences.dart';
import '../models/deep_focus.dart';

/// Простое локальное хранилище профиля (SharedPreferences)
class ProfileService {
  static const _kProfile = 'deep_focus_profile_v1';

  Future<void> save(DeepFocusResult r) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfile, r.toJson().toString());
  }

  Future<DeepFocusResult?> loadFresh() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kProfile);
    return DeepFocusResult.tryParse(s);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfile);
  }
}
