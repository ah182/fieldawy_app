import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldawy_store/features/home/application/user_data_provider.dart';
// ignore: unused_import
import 'package:fieldawy_store/features/home/presentation/screens/home_screen.dart';
// ignore: unused_import
import 'package:fieldawy_store/features/authentication/presentation/screens/role_selection_screen.dart';
import 'package:fieldawy_store/features/authentication/services/auth_service.dart';
import 'package:fieldawy_store/features/authentication/presentation/screens/language_selection_screen.dart';
import 'login_screen.dart';
import 'rejection_screen.dart';
import 'pending_review_screen.dart';
import 'splash_screen.dart';
import 'package:fieldawy_store/features/home/presentation/screens/drawer_wrapper.dart'; // استيراد الغلاف الجديد

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final userData = ref.watch(userDataProvider);
          return userData.when(
            data: (userModel) {
              // هذه الحالة تحدث للحظة وجيزة قبل إنشاء مستند المستخدم
              if (userModel == null) {
                return const SplashScreen();
              }

              // --- هذا هو المنطق الجديد والمصحح ---

              // أولاً، تحقق من الحالات النهائية (مثل الرفض)
              if (userModel.accountStatus == 'rejected') {
                return const RejectionScreen();
              }

              // ثانيًا، تحقق مما إذا كان الملف الشخصي مكتملًا أم لا
              if (!userModel.isProfileComplete) {
                // إذا لم يكن مكتملًا، ابدأ دائمًا من شاشة اختيار اللغة
                return const LanguageSelectionScreen();
              }

              // ثالثًا، إذا كان الملف مكتملًا، تحقق من حالة المراجعة
              if (userModel.accountStatus == 'pending_re_review') {
                return const PendingReviewScreen();
              }

              // أخيرًا، إذا تم كل شيء، اذهب إلى الشاشة الرئيسية
              // (هذا يشمل حالة 'approved' و 'pending_review' للمستخدم الجديد)
              return const DrawerWrapper(); // <-- التغيير هنا
            },
            loading: () => const SplashScreen(),
            error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
          );
        }
        return const LoginScreen();
      },
      loading: () => const SplashScreen(),
      error: (e, s) => Scaffold(body: Center(child: Text('Auth Error: $e'))),
    );
  }
}
