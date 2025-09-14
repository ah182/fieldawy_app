import 'package:fieldawy_store/features/products/application/favorites_provider.dart';
import 'package:fieldawy_store/widgets/main_scaffold.dart';
import 'package:fieldawy_store/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteProductsProvider);

    return MainScaffold(
      selectedIndex: 2,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('favorites'.tr()),
            pinned: true,
          ),
          switch (favoritesAsync) {
            AsyncData(:final value) => value.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'noFavorites'.tr(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = value[index];
                          return ProductCard(
                            product: product,
                            searchQuery: '',
                            onTap: () {
                              // You can add navigation to product details here if you want
                            },
                          );
                        },
                        childCount: value.length,
                      ),
                    ),
                  ),
            AsyncError(:final error) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $error'),
              ),
            ),
            _ => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          }
        ],
      ),
    );
  }
}