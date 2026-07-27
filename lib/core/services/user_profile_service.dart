import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/account_scope.dart';
import '../../features/expenses/data/expense_repository.dart';

class UserProfile {
  final String email;
  final String userId;
  final String name;
  final String emoji;
  final int userVibe;
  final double monthlyBudget;
  final bool hasCompletedOnboarding;
  final DateTime createdAt;

  UserProfile({
    required this.email,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.userVibe,
    required this.monthlyBudget,
    required this.hasCompletedOnboarding,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'userVibe': userVibe,
      'monthlyBudget': monthlyBudget,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'createdAt': createdAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      email: map['email'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '🔥',
      userVibe: (map['userVibe'] ?? 0) as int,
      monthlyBudget: (map['monthlyBudget'] ?? 0).toDouble(),
      hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class UserProfileService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Save user profile to Firestore
  static Future<void> saveUserProfile({
    required String email,
    required String name,
    required String emoji,
    int userVibe = 0,
    required double monthlyBudget,
    bool hasCompletedOnboarding = false,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? email.hashCode.toString();
      final profile = UserProfile(
        email: email,
        userId: userId,
        name: name,
        emoji: emoji,
        userVibe: userVibe,
        monthlyBudget: monthlyBudget,
        hasCompletedOnboarding: hasCompletedOnboarding,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  /// Fetch user profile from Firestore by email
  static Future<UserProfile?> getUserProfileByEmail(String email) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? email.hashCode.toString();
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<UserProfile?> getUserProfileByUid(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Load profile from Firestore and save to local SharedPreferences
  static Future<bool> loadProfileFromFirebase([String? uidOrEmail]) async {
    try {
      final currentUid = uidOrEmail;
      final profile = currentUid == null || currentUid.isEmpty
          ? null
          : await getUserProfileByUid(currentUid);
      if (profile != null) {
        final prefs = await SharedPreferences.getInstance();

        // Save to local preferences
        await prefs.setString(
            AccountScope.scopedPrefKey('userName'), profile.name);
        await prefs.setString(
            AccountScope.scopedPrefKey('userEmoji'), profile.emoji);
        await prefs.setInt(
            AccountScope.scopedPrefKey('userVibe'), profile.userVibe);
        await prefs.setDouble(
            AccountScope.scopedPrefKey('monthlyBudget'), profile.monthlyBudget);
        await prefs.setString('userName', profile.name);
        await prefs.setString('userEmoji', profile.emoji);

        await ExpenseRepository().setUserName(profile.name);
        await ExpenseRepository().setUserEmoji(profile.emoji);
        await ExpenseRepository().setUserVibe(profile.userVibe);
        await ExpenseRepository().setMonthlyBudget(profile.monthlyBudget);
        await ExpenseRepository().setHasCompletedOnboarding(
            profile.hasCompletedOnboarding);

        // Mark onboarding as completed
        await prefs.setBool(
            AccountScope.scopedPrefKey('hasCompletedOnboarding'), true);

        return true;
      }
      return false;
    } catch (e) {
      print('Error loading profile from Firebase: $e');
      return false;
    }
  }
}
