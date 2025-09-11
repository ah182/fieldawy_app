import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: unused_import
import 'features/authentication/presentation/screens/auth_gate.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/language_provider.dart';
import 'features/authentication/data/storage_service.dart';
import 'services/app_state_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();

  // 👇 تنظيف الصور المؤقتة عند بداية التشغيل
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

class FieldawyStoreApp extends ConsumerWidget {
  const FieldawyStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // استدعاء restoreLastRoute عند بداية التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentRouteProvider.notifier).restoreLastRoute();
    });

    final locale = ref.watch(languageProvider);
    // 1. مراقبة الثيم الحالي
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      key: ValueKey(locale),
      debugShowCheckedModeBanner: false,
      title: 'Fieldawy Store',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // 2. تطبيق الثيم المختار مع تحسين الأداء
      themeMode: themeMode,
      // إعدادات إضافية لتحسين أداء تبديل الثيمات
      themeAnimationDuration: const Duration(milliseconds: 200), // تقليل مدة انتقال الثيم
      themeAnimationCurve: Curves.easeOutCubic, // استخدام منحنى انتقال سلس

      home: const AuthGate(),
    );
  }
}
