import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
              colorScheme.secondary.withOpacity(0.6),
            ],
            stops: const [0.0, 0.7, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security,
                            size: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تسجيل دخول آمن',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'loggingIn'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      // === إضافة حد أقصى لعرض الزر على الشاشات الكبيرة ===
      constraints: BoxConstraints(
        maxWidth: isSmallScreen ? double.infinity : 400,
      ),
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _signInWithGoogle,
          borderRadius: BorderRadius.circular(16),
          splashColor: colorScheme.primary.withOpacity(0.1),
          highlightColor: colorScheme.primary.withOpacity(0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // === لوجو Google في مستطيل صغير ===
                Container(
                  width: 45,
                  height: 45,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Image(
                    image: AssetImage('assets/google_icon.png'),
                    width: 29,
                    height: 29,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'signInWithGoogle'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
