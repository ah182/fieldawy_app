import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../widgets/shimmer_loader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ندي فرصة للـ UI يرسم الأول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), _checkAuth);
    });
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // مفيش مستخدم مسجل
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // تحقق لو المستخدم لسه موجود في Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      // المستخدم اتمسح من قاعدة البيانات
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // المستخدم موجود
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect if the system is in dark mode
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Select the appropriate logo and background color
    final logoPath =
        isDarkMode ? 'assets/logo_dark.png' : 'assets/logo_light.png';
    final backgroundColor =
        isDarkMode ? const Color(0xFF0F1220) : const Color(0xFFf3f4f7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage(logoPath),
              width: 300,
            ),
            const SizedBox(height: 34),
            const AttractiveSplashLoader(size: 60),
          ],
        ),
      ),
    );
  }
}
