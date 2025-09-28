/// home_viewmodel.dart — логика главного экрана (offline-first + sync)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/goal_service.dart';
import '../services/local_goal_store.dart';
import '../services/profile_service.dart';
import '../services/numerology_service.dart';

class HomeViewModel extends ChangeNotifier {
  final _auth = AuthService();
  final _goalsCloud = GoalService();
  final _goalsLocal = LocalGoalStore();
  final _profile = ProfileService();
  final _numerology = NumerologyService();

  StreamSubscription<User?>? _authSub;

  bool loading = false;
  List<Goal> items = [];
  User? user;
  UserProfile? profile;

  Future<void> init() async {
    user = _auth.currentUser;
    await _loadAll();

    _authSub = _auth.authStateChanges.listen((u) async {
      final wasAnonymous = user == null;
      user = u;
      if (user != null && wasAnonymous) {
        await _migrateLocalToCloud();
      }
      await _loadAll();
    });
  }

  Future<void> _loadAll() async {
    loading = true; notifyListeners();
    if (user == null) {
      // локальные цели
      final local = await _goalsLocal.load();
      items = local.map((e) => Goal(id: e.id, title: e.title, isCompleted: e.isCompleted)).toList();
      profile = null;
    } else {
      // облачные цели + профиль
      items = await _goalsCloud.fetchGoals(user!.uid);
      profile = await _profile.getProfile(user!.uid);
    }
    loading = false; notifyListeners();
  }

  Future<void> add(String title) async {
    if (user == null) {
      await _goalsLocal.add(title);
    } else {
      await _goalsCloud.addGoal(user!.uid, title);
    }
    await _loadAll();
  }

  Future<void> toggle(Goal g) async {
    if (user == null) {
      await _goalsLocal.toggle(g.id);
    } else {
      await _goalsCloud.toggle(user!.uid, g.id, !g.isCompleted);
    }
    await _loadAll();
  }

  Future<void> remove(Goal g) async {
    if (user == null) {
      await _goalsLocal.remove(g.id);
    } else {
      await _goalsCloud.remove(user!.uid, g.id);
    }
    await _loadAll();
  }

  double get progress {
    if (items.isEmpty) return 0;
    final done = items.where((e) => e.isCompleted).length;
    return done / items.length;
  }

  Future<void> _migrateLocalToCloud() async {
    final local = await _goalsLocal.load();
    if (local.isEmpty || user == null) return;
    await _goalsCloud.addMany(user!.uid, local.map((e) => e.title).toList());
    await _goalsLocal.clear();
  }

  Future<void> saveBirthDateAndSuggest(DateTime date) async {
    if (user == null) return;
    await _profile.saveBirthDate(user!.uid, date);
    final suggestions = _numerology.suggestGoals(date);
    if (suggestions.isNotEmpty) {
      await _goalsCloud.addMany(user!.uid, suggestions);
    }
    await _loadAll();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
