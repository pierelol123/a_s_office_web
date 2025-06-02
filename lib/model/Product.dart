class Product {
  final int productID;
  final String productName;
  final double productPrice;
  final int productCapacity;
  final String imagePath;
  final String dateAdded;
  final String description;
  final int totalQuantitySold;
  final List<dynamic> buyers;

  Product({
    required this.productID,
    required this.productName,
    required this.productPrice,
    required this.productCapacity,
    required this.imagePath,
    required this.dateAdded,
    required this.description,
    required this.totalQuantitySold,
    required this.buyers,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productID: json['ProductID'] ?? 0,
      productName: json['ProductName'] ?? '',
      productPrice: (json['ProductPrice'] ?? 0).toDouble(),
      productCapacity: json['ProductCapacity'] ?? 0,
      imagePath: json['ImagePath'] ?? '',
      dateAdded: json['DateAdded'] ?? '',
      description: json['Description'] ?? '',
      totalQuantitySold: json['totalQuantitySold'] ?? 0,
      buyers: json['buyers'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ProductID': productID,
      'ProductName': productName,
      'ProductPrice': productPrice,
      'ProductCapacity': productCapacity,
      'ImagePath': imagePath,
      'DateAdded': dateAdded,
      'Description': description,
      'totalQuantitySold': totalQuantitySold,
      'buyers': buyers,
    };
  }
}
