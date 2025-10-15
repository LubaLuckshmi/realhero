// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authChanges => _auth.authStateChanges();

  /// Пытаемся войти. Если пользователя не существует — создаём.
  Future<User?> signInOrSignUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      // Если нет такого пользователя — создаём
      if (e.code == 'user-not-found') {
        return _signUp(email: email, password: password);
      }

      // C августа 2024 Firebase часто кидает 'invalid-credential'
      // и для "неверный пароль", и для "нет пользователя".
      // Пробуем отличить кейсы: если пароль >= 6, можно попытаться создать;
      // если почта уже занята — это именно неверный пароль.
      if (e.code == 'invalid-credential') {
        try {
          // проверим: не занята ли почта?
          await _auth
              .createUserWithEmailAndPassword(email: email, password: password)
              .then((c) async {
                await _ensureUserDoc(c.user);
              });
          return _auth.currentUser;
        } on FirebaseAuthException catch (inner) {
          if (inner.code == 'email-already-in-use') {
            // Значит, аккаунт есть, но пароль неверный.
            throw _mapError('wrong-password');
          }
          throw _mapError(inner.code);
        }
      }

      // Другие частые ошибки — мапим и отдаём в UI
      throw _mapError(e.code);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> _signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureUserDoc(cred.user);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e.code);
    }
  }

  Future<void> _ensureUserDoc(User? user) async {
    if (user == null) return;
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'password',
      }, SetOptions(merge: true));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Приводим коды Firebase к человеко-понятным сообщениям (ru)
  Exception _mapError(String code) {
    switch (code) {
      case 'invalid-email':
        return Exception('Некорректный email.');
      case 'user-disabled':
        return Exception('Пользователь деактивирован.');
      case 'user-not-found':
        return Exception('Аккаунт не найден.');
      case 'wrong-password':
        return Exception('Неверный пароль.');
      case 'email-already-in-use':
        return Exception('Такой email уже зарегистрирован.');
      case 'weak-password':
        return Exception('Слабый пароль (минимум 6 символов).');
      case 'too-many-requests':
        return Exception('Слишком много попыток. Попробуйте позже.');
      case 'network-request-failed':
        return Exception('Нет сети. Проверьте подключение к интернету.');
      case 'invalid-credential':
        return Exception('Неверные учётные данные (email/пароль).');
      default:
        return Exception('Ошибка авторизации: $code');
    }
  }
}
