import 'package:easy_localization/easy_localization.dart';
import 'package:fieldawy_store/features/authentication/presentation/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../widgets/shimmer_loader.dart';
import '../../data/user_repository.dart';
import '../../services/auth_service.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  final String documentUrl;
  final String selectedRole;

  const ProfileCompletionScreen({
    super.key,
    required this.documentUrl,
    required this.selectedRole,
  });

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userName =
        ref.read(authServiceProvider).currentUser?.displayName ?? '';
    _nameController = TextEditingController(text: userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. تحديث بيانات المستخدم
      await ref.read(userRepositoryProvider).completeUserProfile(
            uid: user.uid,
            role: widget.selectedRole,
            documentUrl: widget.documentUrl,
            displayName: _nameController.text.trim(),
            whatsappNumber: _phoneController.text.trim(),
          );

      if (!mounted) return;

      // 2. (الحل) العودة إلى AuthGate مع حذف كل الشاشات السابقة
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (Route<dynamic> route) => false, // هذا السطر يحذف كل ما سبق
      );
    } catch (e) {
      if (mounted) {
        // نتأكد من إيقاف التحميل عند حدوث خطأ
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'profileUpdateFailed'.tr()}: $e')),
        );
      }
    }
    // لا نحتاج إلى finally هنا لأننا ننتقل من الشاشة في حالة النجاح
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('completeProfile'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'finalStep'.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'appNameLabel'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'pleaseEnterName'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'whatsappNumberLabel'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'pleaseEnterValidPhone'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(
                    child: ShimmerLoader(
                  width: 40,
                  height: 40,
                  isCircular: true,
                ))
              else
                ElevatedButton(
                  onPressed: _submitProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text('finishAndSave'.tr()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
