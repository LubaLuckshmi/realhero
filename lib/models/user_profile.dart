/// user_profile.dart — профиль (пока только дата рождения)
class UserProfile {
  final DateTime? birthDate;
  const UserProfile({this.birthDate});

  factory UserProfile.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const UserProfile();
    final iso = m['birthDate'] as String?;
    return UserProfile(birthDate: iso == null ? null : DateTime.parse(iso));
  }
}
