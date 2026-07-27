import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'user_model.dart';

class AuthRepository {
  static const String boxName = 'users_box';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<UserModel>(boxName);
    }
  }

  Box<UserModel> get _box => Hive.box<UserModel>(boxName);

  Future<String?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _cacheFirebaseUser(credential.user);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Unable to create account. Please try again.';
    } catch (_) {
      return 'Unable to create account. Please try again.';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _cacheFirebaseUser(credential.user);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Unable to sign in. Please try again.';
    } catch (_) {
      return 'Unable to sign in. Please try again.';
    }
  }

  UserModel? getCurrentUser(String email) {
    final normalized = email.trim().toLowerCase();
    for (final u in _box.values) {
      if (u.email.trim().toLowerCase() == normalized) return u;
    }
    return null;
  }

  Future<void> _cacheFirebaseUser(User? user) async {
    if (user == null) return;
    final cached = UserModel(
      uid: user.uid,
      email: user.email?.trim().toLowerCase() ?? '',
      createdAt: DateTime.now(),
    );
    await _box.put(user.uid, cached);
  }
}
