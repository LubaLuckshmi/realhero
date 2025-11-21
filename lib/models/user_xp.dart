import 'dart:math' as math;

class UserXp {
  final int xp; // общий опыт
  final int level; // текущий уровень
  final int nextLevel; // сколько XP нужно до след. уровня

  const UserXp({
    required this.xp,
    required this.level,
    required this.nextLevel,
  });

  /// Простая кривая: каждые 100 XP — новый уровень (можно усложнить позже).
  factory UserXp.fromXp(int total) {
    final lvl = (total / 100).floor();
    final toNext = ((lvl + 1) * 100) - total;
    return UserXp(xp: total, level: math.max(1, lvl + 1), nextLevel: toNext);
  }
}
