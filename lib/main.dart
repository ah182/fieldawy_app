import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/language_provider.dart';
import 'features/authentication/data/storage_service.dart';
import 'services/app_state_manager.dart';

// تأكد إن المسارات دي صحيحة في مشروعك:
import 'features/authentication/presentation/screens/auth_gate.dart';
import 'features/authentication/presentation/screens/splash_screen.dart';
import 'features/authentication/presentation/screens/login_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();

  // تنظيف الصور المؤقتة عند بداية التشغيل
  final storage = StorageService();
  await storage.cleanupTempImages();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        child: AppStateManager(
          child: const FieldawyStoreApp(),
        ),
      ),
    ),
  );
}

class FieldawyStoreApp extends ConsumerStatefulWidget {
  const FieldawyStoreApp({super.key});

  @override
  ConsumerState<FieldawyStoreApp> createState() => _FieldawyStoreAppState();
}

class _FieldawyStoreAppState extends ConsumerState<FieldawyStoreApp> {
  @override
  void initState() {
    super.initState();
    // استدعاء مرة واحدة فقط بعد أول frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تأكد إن provider موجود؛ هذا السطر يستعيد آخر route محفوظ
      ref.read(currentRouteProvider.notifier).restoreLastRoute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      key: ValueKey(locale),
      debugShowCheckedModeBanner: false,
      title: 'Fieldawy Store',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 200),
      themeAnimationCurve: Curves.easeOutCubic,

      // نستخدم جدول routes عشان Navigator.pushReplacementNamed("/login") يشتغل
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        // ضيف هنا أي routes ثانية تحتاجها، مثال:
        // '/home': (context) => const HomeScreen(),
      },

      // لو جه route غير معرف، نوجّه المستخدم للأب (AuthGate) بدل الرمي بخطأ
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const AuthGate());
      },
    );
  }
}