import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name; // Let's keep name as required, but handle it in fromFirestore
  final String? description;
  final String? activePrinciple;
  final String? company;
  final String? action;
  final String? package;
  final List<String> availablePackages;
  final String imageUrl;
  final double? price;
  final String? distributorId;
  final Timestamp createdAt;
  final String? selectedPackage;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.activePrinciple,
    this.company,
    this.action,
    this.package,
    required this.availablePackages,
    required this.imageUrl,
    this.price,
    this.distributorId,
    required this.createdAt,
    this.selectedPackage,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String packageString = data['package'] ?? '';

    final packages = packageString
        .split('-')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Product', // <-- Provide a default value
      description: data['description'] as String?,
      activePrinciple: data['active_principle'] as String?,
      company: data['company'] as String?,
      action: data['action'] as String?,
      package: packageString,
      availablePackages: packages.isNotEmpty ? packages : [packageString],
      imageUrl: data['imageUrl'] ?? '', // Handle empty URL
      price: (data['price'] as num?)?.toDouble(),
      distributorId: data['distributorId'] as String?,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // دالة مساعدة لنسخ المنتج مع تعديل السعر (مهمة لشاشة أدويتي)
    ProductModel copyWith({
    double? price,
    String? selectedPackage, required String distributorId, // <-- تمت إضافته هنا
  }) {
    return ProductModel(
      id: id,
      name: name,
      description: description,
      activePrinciple: activePrinciple,
      company: company,
      action: action,
      package: package,
      availablePackages: availablePackages,
      imageUrl: imageUrl,
      price: price ?? this.price,
      distributorId: distributorId,
      createdAt: createdAt,
      selectedPackage: selectedPackage ?? this.selectedPackage, // <-- تمت إضافته هنا
    );
  }
}

