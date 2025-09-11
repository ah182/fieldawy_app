import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../widgets/shimmer_loader.dart';
import '../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      if (!mounted) return;
      if (user == null) {
        _showError('loginCancelled'.tr());
      }
    } catch (e) {
      if (mounted) _showError('unexpectedError'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // === إضافة breakpoints للشاشات المختلفة ===
    bool isSmallScreen = size.width < 600;
    bool isTablet = size.width >= 600 && size.width < 1024;
    bool isDesktop = size.width >= 1024;

    // === تحديد أبعاد متكيفة حسب نوع الشاشة ===
    double logoHeight = isSmallScreen
        ? size.height * 0.5 // 30% للشاشات الصغيرة
        : isTablet
            ? size.height * 0.6 // 40% للأجهزة اللوحية
            : size.height * 0.6; // 50% للشاشات الكبيرة

    double horizontalPadding = isSmallScreen
        ? 20.0
        : size.width * 0.1; // 10% من عرض الشاشة للشاشات الكبيرة

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 77, 190, 196),
              const Color.fromARGB(255, 8, 119, 136),
            ],
            stops: const [0.0, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // === مسافة علوية نسبية ===
                    SizedBox(height: size.height * 0.02),

                    // === شعار التطبيق مع ارتفاع متكيف ===
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: logoHeight,
                            maxWidth: isDesktop
                                ? 500
                                : double.infinity, // حد أقصى للشاشات الكبيرة
                          ),
                          child: ClipRect(
                            child: Image.asset(
                              'assets/main_logo.png',
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: logoHeight, // ارتفاع متكيف
                            ),
                          ),
                        ),
                      ),
                    ),

                    // === مسافة نسبية ===
                    SizedBox(height: size.height * 0.07),

                    // === زر تسجيل الدخول المحسن ===
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.5, 1.0,
                              curve: Curves.elasticOut),
                        )),
                        child: _isLoading
                            ? _buildLoadingWidget()
                            : _buildGoogleSignInButton(isSmallScreen),
                      ),
                    ),

                    // === مسافة نسبية ===
                    SizedBox(height: size.height * 0.05),

                    // === معلومات إضافية ===
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: colorScheme.surfaceDim,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'secureLogin'.tr(),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.surface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // === مسافة سفلية نسبية ===
                    SizedBox(height: size.height * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ShimmerLoader(
            width: 24,
            height: 24,
            isCircular: true,
          ),
          const SizedBox(height: 12),
          Text(
            'loggingIn'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(bool isSmallScreen) {
    // ignore: unused_local_variable
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isSmallScreen ? double.infinity : 400,
      ),
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _signInWithGoogle,
        icon: Image.asset(
          'assets/google_icon.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
        label: Text(
          'signInWithGoogle'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shadowColor: Colors.black26,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          iconColor: null, // للحفاظ على ألوان Google الأصلية
        ),
      ),
    );
  }
}
