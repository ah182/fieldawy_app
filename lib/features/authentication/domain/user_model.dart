import 'package:cloud_firestore/cloud_firestore.dart';

// هذا الكلاس هو المخطط لبيانات المستخدم في تطبيقنا
class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String role;
  final String accountStatus;
  final bool isProfileComplete;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    required this.role,
    required this.accountStatus,
    required this.isProfileComplete,
  });

  // دالة لتحويل البيانات من Firestore إلى كائن UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      role: data['role'] as String? ?? 'viewer',
      accountStatus: data['accountStatus'] as String? ?? 'pending_review',
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
    );
  }
}
