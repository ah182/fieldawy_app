import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // في ملف user_repository.dart

// ... (تحت الدوال الأخرى)

// دالة لإعادة بدء عملية التسجيل للمستخدم المرفوض
// في ملف user_repository.dart

// ... (الدوال الأخرى تبقى كما هي)

// دالة لإعادة بدء عملية التسجيل للمستخدم المرفوض
  Future<void> reInitiateOnboarding(String uid) async {
    try {
      // نعيد المستخدم إلى حالة "قيد إعادة المراجعة" وملف غير مكتمل
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'pending_re_review', // <-- التغيير المهم هنا
        'isProfileComplete': false,
      });
    } catch (e) {
      print('Error re-initiating onboarding: $e');
      rethrow;
    }
  }

  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) =>
        snapshot.exists ? UserModel.fromFirestore(snapshot) : null);
  }

  Future<void> saveNewUser(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'viewer',
        'accountStatus': 'pending_review',
        'isProfileComplete': false,
      });
    }
  }

  // --- الدالة الجديدة التي تمت إضافتها ---
  Future<void> completeUserProfile({
    required String uid,
    required String role,
    required String documentUrl,
    required String displayName,
    required String whatsappNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'documentUrl': documentUrl, // حقل جديد لحفظ رابط المستند
        'displayName': displayName,
        'whatsappNumber': whatsappNumber, // حقل جديد لحفظ رقم الواتساب
        'isProfileComplete': true, // الأهم: تغيير حالة اكتمال الملف
      });
    } catch (e) {
      print('Error completing user profile: $e');
      rethrow;
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
