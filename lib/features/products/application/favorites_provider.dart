

import 'package:fieldawy_store/features/products/data/product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldawy_store/features/products/domain/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  static const _favoritesKey = 'favorites';

  String _getUniqueKey(ProductModel product) {
    return '${product.id}_${product.distributorId}_${product.selectedPackage}';
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, state);
  }

  void addToFavorites(ProductModel product) {
    final key = _getUniqueKey(product);
    if (!state.contains(key)) {
      state = [...state, key];
      _saveFavorites();
    }
  }

  void removeFromFavorites(ProductModel product) {
    final key = _getUniqueKey(product);
    state = state.where((k) => k != key).toList();
    _saveFavorites();
  }

  bool isFavorite(ProductModel product) {
    final key = _getUniqueKey(product);
    return state.contains(key);
  }

  void toggleFavorite(ProductModel product) {
    if (isFavorite(product)) {
      removeFromFavorites(product);
    } else {
      addToFavorites(product);
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier();
});

final favoriteProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final favoriteIds = ref.watch(favoritesProvider);
  final allProductsAsync = ref.watch(allDistributorProductsProvider);

  return allProductsAsync.when(
    data: (products) {
      final favoriteProducts = products.where((product) {
        final key = '${product.id}_${product.distributorId}_${product.selectedPackage}';
        return favoriteIds.contains(key);
      }).toList();
      return Stream.value(favoriteProducts);
    },
    loading: () => Stream.value([]),
    error: (error, stackTrace) => Stream.error(error, stackTrace),
  );
});