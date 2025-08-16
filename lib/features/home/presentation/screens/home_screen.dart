import 'package:easy_localization/easy_localization.dart';
import 'package:fieldawy_store/features/products/data/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // مراقبة Stream المنتجات
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ZoomDrawer.of(context)!.toggle(),
        ),
        title: Text('homeScreen'.tr()),
      ),
      body: productsAsync.when(
        data: (products) {
          // إذا لم تكن هناك منتجات، اعرض رسالة
          if (products.isEmpty) {
            return Center(
              child: Text(
                'لا توجد منتجات متاحة حاليًا.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          // إذا كانت هناك منتجات، اعرضها في GridView
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // عرض منتجين في كل صف
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75, // نسبة العرض إلى الارتفاع للبطاقة
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              // سنقوم ببناء بطاقة المنتج هنا
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        // في حالة عدم تحميل الصورة
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.error)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.price} ${'LE'.tr()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('حدث خطأ: $error')),
      ),
    );
  }
}
