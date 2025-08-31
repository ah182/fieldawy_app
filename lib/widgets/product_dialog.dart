import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../features/products/domain/product_model.dart';

class ProductDialog extends StatelessWidget {
  const ProductDialog({super.key, required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الشركة – الاسم – المادة الفعالة
              Text(product.company ?? '', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(product.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              if (product.activePrinciple != null)
                Text(product.activePrinciple!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 16),

              // السـعر
              Text('${product.price?.toStringAsFixed(0) ?? '0'} EGP',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // صورة
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // الوصف + العبوة
           
              const SizedBox(height: 24),

              // زر إجراء
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Vet Eye'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
