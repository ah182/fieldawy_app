// lib/features/products/presentation/screens/my_products_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fieldawy_store/features/products/presentation/screens/add_from_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:fieldawy_store/features/products/data/product_repository.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
// ignore: unnecessary_import
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <= مهم علشان HookConsumerWidget
import 'dart:ui' as ui; // <= لتفادي أي تعارض مع TextDirection
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fieldawy_store/features/products/domain/product_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyProductsScreen extends HookConsumerWidget {
  // <= غيرنا لـ HookConsumerWidget
  const MyProductsScreen({super.key});

  /// دالة علشان تفتح Dialog فيه الصورة بحجمها الطبيعي
  static void _showImagePreviewDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_outlined,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // === استدعاء الـ Provider اللي بيجيب قائمة "أدويةي" ===
    final myProductsAsync = ref.watch(myProductsProvider);

    // === متغير علشان نسيط نص البحث ===
    final searchQuery = useState<String>(''); // <= متغير البحث

    return Scaffold(
      // === تعديل AppBar علشان يحتوي على SearchBar ===
      appBar: AppBar(
        title: Text('myMedicines'.tr()),
        elevation: 2,
        // إضافة SearchBar في الـ AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 16.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) {
                // تحديث نص البحث في الـ state
                searchQuery.value = value;
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...', // <= نص تلميحي
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.value.isNotEmpty // <= زرار مسح لو في نص
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          // مسح النص وتحديث الـ state
                          searchQuery.value = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceVariant, // <= لون خلفية الحقل
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AddFromCatalogScreen()),
            );
          },
          label: Text('addProduct'.tr()),
          icon: const Icon(Icons.add),
          elevation: 4,
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? const Color.fromARGB(255, 44, 214,
                  223) // لون أزرق أكتر صفاءً للوضع النهاري (kBlue)
              : Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(255, 31, 115, 151)
                  : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      body: myProductsAsync.when(
        data: (products) {
          // === فلترة المنتجات حسب نص البحث (في الاسم، الشركة، والمادة الفعالة) ===
          List<ProductModel> filteredProducts;
          if (searchQuery.value.isEmpty) {
            filteredProducts = products;
          } else {
            filteredProducts = products.where((product) {
              // تحويل النص للحروف صغيرة علشان المقارنة تكون case-insensitive
              final query = searchQuery.value.toLowerCase();
              final productName = product.name.toLowerCase();
              // تأكد إن الخواص دي موجودة في ProductModel
              // افتراضيًا إن عندك company و activePrinciple
              final productCompany = product.company?.toLowerCase() ?? '';
              final productActivePrinciple =
                  product.activePrinciple?.toLowerCase() ?? '';

              // بنشوف لو النص موجود في أي واحد من الثلاثة
              return productName.contains(query) ||
                  productCompany.contains(query) ||
                  productActivePrinciple.contains(query);
            }).toList();
          }

          if (filteredProducts.isEmpty) {
            // === عرض رسالة مناسبة لو مفيش نتائج للبحث ===
            if (searchQuery.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_outlined, // <= أيقونة مناسبة
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد نتائج للبحث.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              );
            } else {
              // === لو مفيش منتجات أصلاً ===
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You have not added any medicines yet.'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AddFromCatalogScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('addProduct'.tr()),
                    ),
                  ],
                ),
              );
            }
          }

          // === عرض قائمة المنتجات المفلترة ===
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80.0),
            itemCount: filteredProducts.length, // <= عدد العناصر المفلترة
            itemBuilder: (context, index) {
              final product =
                  filteredProducts[index]; // <= استخدام المنتج المفلتر
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GestureDetector(
                      onTap: () {
                        _showImagePreviewDialog(context, product.imageUrl);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                const Icon(Icons.medication, size: 30),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error_outline, size: 30),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (product.selectedPackage != null &&
                            product.selectedPackage!.isNotEmpty)
                          Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
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
                                    ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${product.price?.toStringAsFixed(2) ?? '0.00'} ',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              TextSpan(
                                text: 'EGP'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blue),
                          onPressed: () {
                            // Edit logic will go here
                          },
                          tooltip: 'edit'.tr(),
                          splashRadius: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () {
                            // Delete logic will go here
                          },
                          tooltip: 'delete'.tr(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '${'An error occurred:'.tr()} $error',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
