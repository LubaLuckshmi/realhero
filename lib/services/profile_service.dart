// profile_service.dart — профиль пользователя (дата рождения) в users/{uid}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    final data = Map<String, dynamic>.from(snap.data() ?? {});
    data.remove('goals'); // на всякий случай
    return UserProfile.fromMap(data);
  }

  Future<void> saveBirthDate(String uid, DateTime birthDate) async {
    await _doc(
      uid,
    ).set({'birthDate': birthDate.toIso8601String()}, SetOptions(merge: true));
  }
}

