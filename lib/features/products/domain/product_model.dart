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
  final Timestamp? createdAt;
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
    this.createdAt,
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
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? activePrinciple,
    String? company,
    String? action,
    String? package,
    List<String>? availablePackages,
    String? imageUrl,
    double? price,
    String? distributorId,
    Timestamp? createdAt,
    String? selectedPackage,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      activePrinciple: activePrinciple ?? this.activePrinciple,
      company: company ?? this.company,
      action: action ?? this.action,
      package: package ?? this.package,
      availablePackages: availablePackages ?? this.availablePackages,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      distributorId: distributorId ?? this.distributorId,
      createdAt: createdAt ?? this.createdAt,
      selectedPackage: selectedPackage ?? this.selectedPackage,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'active_principle': activePrinciple,
      'company': company,
      'action': action,
      'package': package,
      'availablePackages': availablePackages,
      'imageUrl': imageUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
