import 'package:a_s_office_web/model/Product.dart';
// Catalog introduction and index classes
class CatalogIntro {
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final String contactInfo;
  final DateTime lastUpdated;

  CatalogIntro({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.contactInfo,
    required this.lastUpdated,
  });

  factory CatalogIntro.fromJson(Map<String, dynamic> json) {
    return CatalogIntro(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      description: json['description'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      contactInfo: json['contactInfo'] ?? '',
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'features': features,
      'contactInfo': contactInfo,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class CatalogIndex {
  final List<CatalogSection> sections;

  CatalogIndex({required this.sections});

  factory CatalogIndex.fromProducts(List<Product> products) {
    final Map<int, List<Product>> productsByPage = {};
    
    for (final product in products) {
      if (!productsByPage.containsKey(product.pageNumber)) {
        productsByPage[product.pageNumber] = [];
      }
      productsByPage[product.pageNumber]!.add(product);
    }

    final sections = productsByPage.entries.map((entry) {
      final pageNum = entry.key;
      final pageProducts = entry.value;
      
      return CatalogSection(
        pageNumber: pageNum,
        title: 'עמוד $pageNum',
        productCount: pageProducts.length,
        products: pageProducts.map((p) => p.productName).toList(),
      );
    }).toList();

    sections.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    
    return CatalogIndex(sections: sections);
  }
}

class CatalogSection {
  final int pageNumber;
  final String title;
  final int productCount;
  final List<String> products;

  CatalogSection({
    required this.pageNumber,
    required this.title,
    required this.productCount,
    required this.products,
  });
}