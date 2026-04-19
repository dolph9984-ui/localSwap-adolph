import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String city;
  final List<String> imageUrls;
  final GeoPoint? location;
  final DateTime createdAt;
  final bool isSold;

  final String? address;

  // Champs facultatifs
  final String? brand;
  final String? modelName;
  final String? reference;
  final String? size;
  final String? color;
  final String? material;
  final double? weight;

  const ListingModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.city,
    required this.imageUrls,
    this.location,
    required this.createdAt,
    this.isSold = false,

    this.address,

    this.brand,
    this.modelName,
    this.reference,
    this.size,
    this.color,
    this.material,
    this.weight,
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      id: doc.id,
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? 'Inconnu',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? '',
      condition: data['condition'] as String? ?? '',
      city: data['city'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      location: data['location'] as GeoPoint?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSold: data['isSold'] as bool? ?? false,

      address: data['address'] as String?,

      brand: data['brand'] as String?,
      modelName: data['modelName'] as String?,
      reference: data['reference'] as String?,
      size: data['size'] as String?,
      color: data['color'] as String?,
      material: data['material'] as String?,
      weight: (data['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'city': city,
      'imageUrls': imageUrls,
      if (location != null) 'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'isSold': isSold,

      if (address != null) 'address': address,

      if (brand != null) 'brand': brand,
      if (modelName != null) 'modelName': modelName,
      if (reference != null) 'reference': reference,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (material != null) 'material': material,
      if (weight != null) 'weight': weight,
    };
  }

  ListingModel copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    String? city,
    List<String>? imageUrls,
    GeoPoint? location,
    DateTime? createdAt,
    bool? isSold,

    String? address,

    String? brand,
    String? modelName,
    String? reference,
    String? size,
    String? color,
    String? material,
    double? weight,
  }) {
    return ListingModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      city: city ?? this.city,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      isSold: isSold ?? this.isSold,

      address: address ?? this.address,

      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      reference: reference ?? this.reference,
      size: size ?? this.size,
      color: color ?? this.color,
      material: material ?? this.material,
      weight: weight ?? this.weight,
    );
  }
}