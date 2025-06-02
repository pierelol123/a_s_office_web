import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:a_s_office_web/model/Product.dart';

class ProductService {
  static Future<List<Product>> loadProducts() async {
    try {
      final String jsonString = await rootBundle.loadString('lib/data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> productsJson = jsonData['products'] ?? [];
      
      return productsJson
          .map((productJson) => Product.fromJson(productJson))
          .where((product) => product.productName.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }

  static List<Product> filterProducts(List<Product> products, String query) {
    if (query.isEmpty) return products;
    
    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      return product.productName.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static Future<bool> saveProductsToFile(List<Product> products) async {
    try {
      final Map<String, dynamic> data = {
        'products': products.map((product) => product.toJson()).toList(),
        'metadata': {
          'totalProducts': products.length,
          'lastUpdated': DateTime.now().toIso8601String(),
          'version': '1.0',
        },
      };

      final String jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // For web, you might need to use a different approach
      // This is for desktop/mobile applications
      final File file = File('lib/data.json');
      await file.writeAsString(jsonString);
      
      return true;
    } catch (e) {
      print('Error saving products: $e');
      return false;
    }
  }

  static Future<bool> updateProduct(List<Product> allProducts, Product updatedProduct) async {
    try {
      final index = allProducts.indexWhere((p) => p.productID == updatedProduct.productID);
      if (index != -1) {
        allProducts[index] = updatedProduct;
        return await saveProductsToFile(allProducts);
      }
      return false;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(List<Product> allProducts, int productID) async {
    try {
      allProducts.removeWhere((product) => product.productID == productID);
      return await saveProductsToFile(allProducts);
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }
}