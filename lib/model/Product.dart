class Product {
  final int productID;
  final String productName;
  final double productPrice;
  final int productCapacity;
  final String? productSku; // New SKU field
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
    this.productSku, // Optional field
    required this.imagePath,
    required this.dateAdded,
    required this.description,
    required this.totalQuantitySold,
    required this.buyers,
    required this.pageNumber,
    required this.rowInPage,
    required this.height,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productID: json['ProductID'] ?? 0,
      productName: json['ProductName'] ?? '',
      productPrice: (json['ProductPrice'] ?? 0).toDouble(),
      productCapacity: json['ProductCapacity'] ?? 0,
      productSku: json['ProductSku'], // New field
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
      'ProductSku': productSku, // New field
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
}