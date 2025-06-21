class ProductVariant {
  final String color;
  final String sku;
  final String? colorHex; // Optional hex color code for display
  final String? additionalNotes; // Any additional notes for this variant

  ProductVariant({
    required this.color,
    required this.sku,
    this.colorHex,
    this.additionalNotes,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      color: json['color'] ?? '',
      sku: json['sku'] ?? '',
      colorHex: json['colorHex'],
      additionalNotes: json['additionalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'sku': sku,
      if (colorHex != null) 'colorHex': colorHex,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
    };
  }

  @override
  String toString() {
    return 'ProductVariant(color: $color, sku: $sku, colorHex: $colorHex)';
  }
}

class Product {
  final int productID;
  final String productName;
  final double productPrice;
  final int productCapacity;
  final String? productSku;
  final List<ProductVariant> variants; // Add variants field
  final String imagePath;
  final String dateAdded;
  final String description;
  final int totalQuantitySold;
  final List<dynamic> buyers;
  final int pageNumber;
  final int rowInPage;
  final double height;

  Product({
    required this.productID,
    required this.productName,
    required this.productPrice,
    required this.productCapacity,
    this.productSku,
    this.variants = const [], // Default to empty list
    required this.imagePath,
    required this.dateAdded,
    required this.description,
    required this.totalQuantitySold,
    required this.buyers,
    required this.pageNumber,
    required this.rowInPage,
    required this.height,
  });

  // Helper method to get all SKUs (main + variants)
  List<String> getAllSkus() {
    final skus = <String>[];
    if (productSku != null && productSku!.isNotEmpty) {
      skus.add(productSku!);
    }
    skus.addAll(variants.map((v) => v.sku).where((sku) => sku.isNotEmpty));
    return skus;
  }

  // Helper method to check if product has variants
  bool get hasVariants => variants.isNotEmpty;

  // Helper method to get variant by color
  ProductVariant? getVariantByColor(String color) {
    try {
      return variants.firstWhere((v) => v.color.toLowerCase() == color.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productID: json['ProductID'] ?? 0,
      productName: json['ProductName'] ?? '',
      productPrice: (json['ProductPrice'] ?? 0).toDouble(),
      productCapacity: json['ProductCapacity'] ?? 0,
      productSku: json['ProductSku'],
      variants: (json['variants'] as List<dynamic>?)
          ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList() ?? [],
      imagePath: json['ImagePath'] ?? '',
      dateAdded: json['DateAdded'] ?? '',
      description: json['Description'] ?? '',
      totalQuantitySold: json['totalQuantitySold'] ?? 0,
      buyers: json['buyers'] ?? [],
      pageNumber: json['pageNumber'] ?? 1,
      rowInPage: json['rowInPage'] ?? 1,
      height: (json['height'] ?? 160.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ProductID': productID,
      'ProductName': productName,
      'ProductPrice': productPrice,
      'ProductCapacity': productCapacity,
      'ProductSku': productSku,
      'variants': variants.map((v) => v.toJson()).toList(),
      'ImagePath': imagePath,
      'DateAdded': dateAdded,
      'Description': description,
      'totalQuantitySold': totalQuantitySold,
      'buyers': buyers,
      'pageNumber': pageNumber,
      'rowInPage': rowInPage,
      'height': height,
    };
  }

  @override
  String toString() {
    return 'Product(id: $productID, name: $productName, price: $productPrice, sku: $productSku, variants: ${variants.length})';
  }
}