import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldawy_store/features/authentication/services/auth_service.dart';
import 'package:fieldawy_store/features/products/domain/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// دالة لجلب كل المنتجات من الكتالوج الرئيسي للتطبيق
  Stream<List<ProductModel>> getAllProductsStream() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  /// دالة لإضافة منتجات متعددة دفعة واحدة إلى كتالوج الموزع
  Future<void> addMultipleProductsToDistributorCatalog({
    required String distributorId,
    required String distributorName,
    required Map<String, double> productsToAdd,
  }) async {
    final batch = _firestore.batch();

    productsToAdd.forEach((uniqueKey, price) {
      final parts = uniqueKey.split('_');
      final productId = parts[0];
      final package = parts.sublist(1).join('_');

      final docId = '${distributorId}_$uniqueKey';
      final docRef = _firestore.collection('distributorProducts').doc(docId);
      batch.set(docRef, {
        'distributorId': distributorId,
        'distributorName': distributorName,
        'productId': productId,
        'package': package,
        'price': price,
        'addedAt': FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
  }

  /// دالة لإزالة منتج من كتالوج الموزع
  Future<void> removeProductFromDistributorCatalog({
    required String distributorId,
    required String productId,
    required String package,
  }) async {
    final uniqueKey = '${productId}_$package';
    final docId = '${distributorId}_$uniqueKey';
    await _firestore.collection('distributorProducts').doc(docId).delete();
  }
}

// --- Providers ---

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).getAllProductsStream();
});
// Provider لجلب منتجات جميع الموزعين مع الأسعار
final allDistributorProductsProvider =
    StreamProvider<List<ProductModel>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('distributorProducts')
      .snapshots()
      .asyncMap((distributorSnapshot) async {
    if (distributorSnapshot.docs.isEmpty) {
      return [];
    }

    // استخراج البيانات من منتجات الموزعين
    final productLinks = distributorSnapshot.docs
        .map((doc) => doc.data())
        .where((data) =>
            data['productId'] != null &&
            data['price'] != null &&
            data['package'] != null &&
            data['distributorName'] != null)
        .toList();

    if (productLinks.isEmpty) return [];

    final productIds = productLinks
        .map((link) => link['productId'] as String)
        .toSet()
        .toList();

    // جلب تفاصيل المنتجات من المجموعة الرئيسية
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> allProductDocs = [];
    for (var i = 0; i < productIds.length; i += 30) {
      final sublist = productIds.sublist(
          i, i + 30 > productIds.length ? productIds.length : i + 30);
      if (sublist.isNotEmpty) {
        final productDocsSnapshot = await firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        allProductDocs.addAll(productDocsSnapshot.docs);
      }
    }

    // تحويل تفاصيل المنتجات إلى خريطة
    final productsMap = {
      for (var doc in allProductDocs) doc.id: ProductModel.fromFirestore(doc)
    };

    // دمج البيانات النهائية
    final allDistributorProducts = productLinks
        .map((link) {
          final productDetails = productsMap[link['productId']];

          if (productDetails != null) {
            return productDetails.copyWith(
              price: (link['price'] as num).toDouble(),
              selectedPackage: link['package'] as String,
              distributorId: link['distributorName'] as String, // اسم الموزع
            );
          }
          return null;
        })
        .whereType<ProductModel>()
        .toList();

    return allDistributorProducts;
  });
});

// --- Provider "أدويتي" (النسخة النهائية والمصححة) ---
final myProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final userId = ref.watch(authServiceProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  final firestore = FirebaseFirestore.instance;

  // 1. الاستماع لقائمة منتجات الموزع (التي تحتوي على الأسعار والأحجام)
  final distributorProductsStream = firestore
      .collection('distributorProducts')
      .where('distributorId', isEqualTo: userId)
      .snapshots();

  // 2. تحويل قائمة الروابط هذه إلى قائمة منتجات كاملة بالتفاصيل
  return distributorProductsStream.asyncMap((distributorSnapshot) async {
    if (distributorSnapshot.docs.isEmpty) {
      return [];
    }

    // استخراج البيانات من قائمة الموزع بأمان
    final productLinks = distributorSnapshot.docs
        .map((doc) => doc.data())
        .where((data) =>
            data['productId'] != null &&
            data['price'] != null &&
            data['package'] != null)
        .toList();

    if (productLinks.isEmpty) return [];

    final productIds = productLinks
        .map((link) => link['productId'] as String)
        .toSet()
        .toList();

    // 3. جلب تفاصيل هذه المنتجات من المجموعة الرئيسية في دفعات
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> allProductDocs = [];
    for (var i = 0; i < productIds.length; i += 30) {
      final sublist = productIds.sublist(
          i, i + 30 > productIds.length ? productIds.length : i + 30);
      if (sublist.isNotEmpty) {
        final productDocsSnapshot = await firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        allProductDocs.addAll(productDocsSnapshot.docs);
      }
    }

    // تحويل تفاصيل المنتجات إلى خريطة ليسهل الوصول إليها
    final productsMap = {
      for (var doc in allProductDocs) doc.id: ProductModel.fromFirestore(doc)
    };

    // 4. دمج البيانات النهائية (تفاصيل المنتج + سعر وحجم الموزع المحدد)
    final myFinalProducts = productLinks
        .map((link) {
          final productDetails = productsMap[link['productId']];

          if (productDetails != null) {
            // نأخذ تفاصيل المنتج الأصلية ونقوم بتحديث السعر وحجم العبوة المختار
            return productDetails.copyWith(
              price: (link['price'] as num).toDouble(),
              selectedPackage: link['package'] as String,
              distributorId: link['distributorName'] as String,
            );
          }
          return null;
        })
        .whereType<ProductModel>()
        .toList(); // تجاهل أي نتائج فارغة

    return myFinalProducts;
  });
});
