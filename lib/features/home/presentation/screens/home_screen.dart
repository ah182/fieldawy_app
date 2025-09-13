import 'package:easy_localization/easy_localization.dart';
import 'package:fieldawy_store/features/products/data/product_repository.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fieldawy_store/features/products/domain/product_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fieldawy_store/widgets/shimmer_loader.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';

import '../../application/user_data_provider.dart';
import 'package:fieldawy_store/features/profile/presentation/screens/profile_screen.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  // دالة مساعدة لحساب نقاط الأولوية في البحث
  int _calculateSearchScore(ProductModel product, String query) {
    int score = 0;

    final productName = product.name.toLowerCase();
    final activePrinciple = (product.activePrinciple ?? '').toLowerCase();
    final distributorName = (product.distributorId ?? '').toLowerCase();
    final company = (product.company ?? '').toLowerCase();
    final packageSize = (product.selectedPackage ?? '').toLowerCase();
    final description = (product.description ?? '').toLowerCase();

    // نقاط عالية للمطابقات المهمة
    if (productName.contains(query)) score += 10;
    if (activePrinciple.contains(query)) score += 8;
    if (distributorName.contains(query)) score += 6;

    // نقاط متوسطة للمطابقات الثانوية
    if (company.contains(query)) score += 4;
    if (packageSize.contains(query)) score += 2;
    if (description.contains(query)) score += 2;

    // نقاط إضافية للمطابقة في بداية النص
    if (productName.startsWith(query)) score += 5;
    if (activePrinciple.startsWith(query)) score += 3;
    if (distributorName.startsWith(query)) score += 3;

    return score;
  }

  // دالة لإظهار ديالوج تفاصيل المنتج مع أنيميشن احترافي
  // دالة لإظهار ديالوج تفاصيل المنتج مع أنيميشن احترافي
  void _showProductDetailDialog(BuildContext context, ProductModel product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: _buildProductDetailDialog(context, product),
          ),
        );
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation1,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation1,
            child: child,
          ),
        );
      },
    );
  }

// بناء ديالوج تفاصيل المنتج - مُصحح
  // بناء ديالوج تفاصيل المنتج - مع دعم الثيم الداكن والفاتح
  Widget _buildProductDetailDialog(BuildContext context, ProductModel product) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // دالة لتصحيح ترتيب نص العبوة للغة العربية
    String formatPackageText(String package) {
      final currentLocale = Localizations.localeOf(context).languageCode;

      if (currentLocale == 'ar' &&
          package.toLowerCase().contains(' ml') &&
          package.toLowerCase().contains('vial')) {
        final parts = package.split(' ');
        if (parts.length >= 3) {
          final number = parts.firstWhere(
              (part) => RegExp(r'^\d+').hasMatch(part),
              orElse: () => '');
          final unit = parts.firstWhere(
              (part) => part.toLowerCase().contains(' ml'),
              orElse: () => '');
          final container = parts.firstWhere(
              (part) => part.toLowerCase().contains('vial'),
              orElse: () => '');

          if (number.isNotEmpty && unit.isNotEmpty && container.isNotEmpty) {
            return '$number$unit $container';
          }
        }
      }
      return package;
    }

    // ألوان حسب الثيم
    // ignore: unused_local_variable
    final backgroundGradient = isDark
        ? LinearGradient(
            colors: [
              Color(0xFF1E1E2E), // داكن بنفسجي
              Color(0xFF2A2A3A), // داكن رمادي
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Color(0xFFE3F2FD), // أزرق فاتح (التصميم الأصلي)
              Color(0xFFF8FDFF), // أبيض مع لمسة زرقاء
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final containerColor = isDark
        ? Colors.grey.shade800.withOpacity(0.5)
        : Colors.white.withOpacity(0.8);
    final iconColor = isDark ? Colors.white70 : theme.colorScheme.primary;
    final priceColor =
        isDark ? Colors.lightGreenAccent.shade200 : Colors.green.shade700;
    final favoriteColor =
        isDark ? Colors.redAccent.shade100 : Colors.red.shade400;
   final packageBgColor = isDark
        ? const Color.fromARGB(255, 216, 222, 249).withOpacity(0.1)
        : Colors.blue.shade50.withOpacity(0.8);
    final packageBorderColor = isDark
        ? const Color.fromARGB(255, 102, 126, 162)
        : Colors.blue.shade200;
    final imageBgColor = isDark
        ? const Color.fromARGB(255, 21, 15, 15).withOpacity(0.3)
        : Colors.white.withOpacity(0.7);
        final backgroundColor =
        isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE3F2FD);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: isSmallScreen ? size.width * 0.95 : 400,
        height: size.height * 0.85,
        decoration: BoxDecoration(
         color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.grey.shade600.withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Header مع badge الموزع ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: containerColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: iconColor),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      // Badge اسم الموزع
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          product.distributorId ?? 'موزع غير معروف',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // === اسم الشركة ===
                  if (product.company != null && product.company!.isNotEmpty)
                    Text(
                      product.company!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // === اسم المنتج ===
                  Text(
                    product.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // === المادة الفعالة ===
                  if (product.activePrinciple != null &&
                      product.activePrinciple!.isNotEmpty)
                    Text(
                      product.activePrinciple!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // === السعر مع أيقونة القلب ===
                  Row(
                    children: [
                      Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: Text(
                          '${product.price?.toStringAsFixed(0) ?? '0'} ${'EGP'.tr()}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: priceColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: containerColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.favorite_border,
                            color: favoriteColor,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                content: AwesomeSnackbarContent(
                                  title: 'نجاح',
                                  message: 'addedToFavorites'
                                      .tr(args: [product.name]),
                                  contentType: ContentType.success,
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // === صورة المنتج ===
                  Center(
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: imageBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                              child: ImageLoadingIndicator(
                            size: 50,
                          )),
                        errorWidget: (context, url, error) => Icon(
                          Icons.broken_image_outlined,
                          size: 60,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === وصف المنتج ===
                  Text(
                    'Active principle',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 8),

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: product.activePrinciple ?? 'غير محدد',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === حجم العبوة مُصغر بدون كلمة Size ===
                  if (product.selectedPackage != null &&
                      product.selectedPackage!.isNotEmpty)
                   Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: packageBgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: packageBorderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: isDark
                                  ? const Color.fromARGB(255, 6, 149, 245)
                                  : const Color.fromARGB(255, 4, 90, 160),
                            ),
                            const SizedBox(width: 8),
                            Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: Text(
                                formatPackageText(product.selectedPackage!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // === رسالة التطبيق - مُكبرة ===
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer.withOpacity(0.3),
                            theme.colorScheme.secondaryContainer
                                .withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              
                              Expanded(
                                child: Text(
                                  'لمزيد من المعلومات يرجى تنزيل تطبيق',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse(
                                  'https://apkpure.net/ar/vet-eye/com.fieldawy.veteye/download/7.5.1');
                              try {
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    elevation: 0,
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.transparent,
                                    content: AwesomeSnackbarContent(
                                      title: 'تنبيه',
                                      message: 'تعذر فتح الرابط',
                                      contentType: ContentType.warning,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.download_outlined,
                                    color: theme.colorScheme.onPrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Vet Eye',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // مراقبة Stream منتجات جميع الموزعين مع الأسعار
    final productsAsync = ref.watch(allDistributorProductsProvider);

    // متغير البحث مع TextEditingController
    final searchQuery = useState<String>('');
    final searchController = useTextEditingController();
    final focusNode = useFocusNode();
    final debouncedSearchQuery = useState<String>('');
    
    // تحديث البحث بعد تأخير قصير
    useEffect(() {
      final timer = Timer(Duration(milliseconds: 500), () {
        debouncedSearchQuery.value = searchQuery.value;
      });
      return timer.cancel;
    }, [searchQuery.value]);

    final sliverAppBar = SliverAppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => ZoomDrawer.of(context)!.toggle(),
      ),
      title: Text('homeScreen'.tr()),
      elevation: 0,
      scrolledUnderElevation: 0,
      forceElevated: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      pinned: true,
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final userDataAsync = ref.watch(userDataProvider);
            return userDataAsync.when(
              data: (user) {
                if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0).add(const EdgeInsets.only(top: 4.0)),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user.photoURL!,
                              width: 29,
                              height: 29,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 50.0),
        child: Column(
          children: [
            // === شريط البحث المُحسن ===
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  focusNode: focusNode,
                  onChanged: (value) {
                    searchQuery.value = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن دواء، مادة فعالة...',
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    suffixIcon: searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              searchController.clear();
                              searchQuery.value = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        // إزالة التركيز من شريط البحث عند النقر في أي مكان آخر
        focusNode.unfocus();
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allDistributorProductsProvider);
          await ref.read(allDistributorProductsProvider.future);
        },
        child: productsAsync.when(
          data: (products) {
            // === فلترة المنتجات حسب البحث المحسن ===
            List<ProductModel> filteredProducts;
            if (debouncedSearchQuery.value.isEmpty) {
              // إذا لم يكن هناك بحث، اعرض منتجات عشوائية
              final random = Random();
              final List<ProductModel> shuffledProducts = List.from(products)
                ..shuffle(random);
              filteredProducts = shuffledProducts.length > 25
                  ? shuffledProducts.sublist(0, 25)
                  : shuffledProducts;
            } else {
              // فلترة محسنة حسب نص البحث
              filteredProducts = products.where((product) {
                final query = debouncedSearchQuery.value.toLowerCase().trim();

                // === البحث الأساسي ===
                final productName = product.name.toLowerCase(); // اسم الدواء
                final distributorName =
                    (product.distributorId ?? '').toLowerCase(); // اسم الموزع
                final activePrinciple = (product.activePrinciple ?? '')
                    .toLowerCase(); // المادة الفعالة

                // === البحث الإضافي ===
                final packageSize =
                    (product.selectedPackage ?? '').toLowerCase(); // حجم العبوة
                final company = (product.company ?? '').toLowerCase(); // الشركة المصنعة
                final description = (product.description ?? '').toLowerCase(); // وصف المنتج
                final action = (product.action ?? '').toLowerCase(); // آلية العمل

                // === البحث الشامل مع الأولوية ===
                // أولوية عالية: اسم الدواء، المادة الفعالة، اسم الموزع
                bool highPriorityMatch = productName.contains(query) ||
                    activePrinciple.contains(query) ||
                    distributorName.contains(query);

                // أولوية متوسطة: الشركة، العبوة، الوصف
                bool mediumPriorityMatch = company.contains(query) ||
                    packageSize.contains(query) ||
                    description.contains(query);

                // أولوية منخفضة: آلية العمل
                bool lowPriorityMatch = action.contains(query);

                return highPriorityMatch ||
                    mediumPriorityMatch ||
                    lowPriorityMatch;
              }).toList();

              // === ترتيب النتائج حسب الأولوية ===
              filteredProducts.sort((a, b) {
                final query = debouncedSearchQuery.value.toLowerCase().trim();

                // حساب نقاط الأولوية لكل منتج
                int scoreA = _calculateSearchScore(a, query);
                int scoreB = _calculateSearchScore(b, query);

                return scoreB.compareTo(scoreA); // ترتيب تنازلي
              });
            }

            return CustomScrollView(
              slivers: [
                sliverAppBar,
                if (products.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد منتجات متاحة حاليًا.',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: debouncedSearchQuery.value.isEmpty
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3)
                            : Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: debouncedSearchQuery.value.isEmpty
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2)
                              : Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            debouncedSearchQuery.value.isEmpty
                                ? Icons.storefront_outlined
                                : Icons.search_outlined,
                            size: 16,
                            color: debouncedSearchQuery.value.isEmpty
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            debouncedSearchQuery.value.isEmpty
                                ? 'عرض ${filteredProducts.length} منتج من أحدث العروض'
                                : 'وُجد ${filteredProducts.length} منتج${filteredProducts.length == 1 ? '' : (filteredProducts.length <= 10 ? 'ات' : '')}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: debouncedSearchQuery.value.isEmpty
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filteredProducts.isEmpty &&
                      debouncedSearchQuery.value.isNotEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 60,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج للبحث عن "${debouncedSearchQuery.value}"',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جرب البحث عن:\n• اسم الدواء أو المادة الفعالة\n• اسم الموزع أو الشركة\n• حجم العبوة أو الوصف',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                searchController.clear(); // مسح النص
                                searchQuery.value = ''; // تحديث الحالة
                              },
                              icon: const Icon(Icons.clear, size: 18),
                              label: const Text('مسح البحث'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 1.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(
                                context, product, debouncedSearchQuery.value);
                          },
                          childCount: filteredProducts.length,
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
          loading: () => CustomScrollView(
            slivers: [
              sliverAppBar,
              SliverFillRemaining(
                child: ListView.builder(
                  itemCount: 6,
                  padding: const EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ProductCardShimmer(),
                    );
                  },
                ),
              ),
            ],
          ),
          error: (error, stack) => CustomScrollView(
            slivers: [
              sliverAppBar,
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text('حدث خطأ: $error', 
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          // إعادة تحميل البيانات
                          ref.invalidate(allDistributorProductsProvider);
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, ProductModel product, String searchQuery) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: Theme.of(context).shadowColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // === عرض ديالوج تفاصيل المنتج ===
          _showProductDetailDialog(context, product);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === صورة المنتج مع أيقونة المفضلة ===
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.3),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                            child: ImageLoadingIndicator(size: 50)),
                      errorWidget: (context, url, error) => Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 24,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  // === أيقونة المفضلة ===
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.favorite_border),
                        iconSize: 14,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'نجاح',
                                message:
                                    'تمت إضافة ${product.name} للمفضلة',
                                contentType: ContentType.success,
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  // === مؤشر نتائج البحث ===
                  if (searchQuery.isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // === معلومات المنتج ===
            Flexible(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // === اسم المنتج ===
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // === السعر ===
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.price?.toStringAsFixed(0) ?? '0'} ${'LE'.tr()}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    // === اسم الموزع ===
                    Row(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product.distributorId ?? 'موزع غير معروف',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                  fontSize: 9,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // === حجم العبوة ===
                    if (product.selectedPackage != null &&
                        product.selectedPackage!.isNotEmpty &&
                        product.selectedPackage!.length < 15)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.selectedPackage!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
