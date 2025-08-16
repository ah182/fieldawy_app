import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fieldawy_store/features/authentication/presentation/screens/role_selection_screen.dart';
import 'package:fieldawy_store/features/authentication/services/auth_service.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void selectLanguage(Locale locale) {
      // استخدام الطريقة المضمونة من easy_localization لتغيير اللغة
      context.setLocale(locale).then((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        // زر الرجوع الذي يقوم بتسجيل الخروج
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'العودة لتسجيل الدخول',
          onPressed: () {
            ref.read(authServiceProvider).signOut();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose Your Language',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'chooseYourLanguage'.tr(),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
                _buildLanguageCard(
                  context: context,
                  language: 'English',
                  onTap: () => selectLanguage(const Locale('en')),
                ),
                const SizedBox(height: 24),
                _buildLanguageCard(
                  context: context,
                  language: 'العربية',
                  onTap: () => selectLanguage(const Locale('ar')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String language,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Center(
          child: Text(
            language,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}
