import 'dart:ui';

import 'package:a_s_office_web/model/Product.dart';
import 'package:flutter/material.dart';

class PdfCapacityCalculator {
  // PDF page dimensions (using your actual settings)
  static const double _PAGE_HEIGHT = 930.0; // From your pdf_builders.dart
  static const double _PAGE_MARGIN = 5.0; // From your pdf_builders.dart
  static const double _PAGE_HEADER_HEIGHT = 20.0; // From your pdf_builders.dart
  static const double _AVAILABLE_HEIGHT = _PAGE_HEIGHT - (_PAGE_MARGIN * 2) - _PAGE_HEADER_HEIGHT;
  
  static PdfPageCapacity calculatePageCapacity(List<Product> products) {
    if (products.isEmpty) {
      return PdfPageCapacity(
        canFitInSinglePage: true,
        estimatedHeight: _PAGE_HEADER_HEIGHT + 50,
        availableHeight: _AVAILABLE_HEIGHT,
        utilizationPercentage: 0.0,
        productHeights: [],
        warnings: [],
      );
    }
    
    double totalEstimatedHeight = 0.0;
    List<double> productHeights = [];
    List<String> warnings = [];
    
    for (final product in products) {
      double productHeight = _estimateProductHeight(product);
      productHeights.add(productHeight);
      totalEstimatedHeight += productHeight;
      
      // Check for potential issues
      if (product.productName.length > 100) {
        warnings.add('${product.productName} - שם ארוך מדי');
      }
      if (product.description.length > 500) {
        warnings.add('${product.productName} - תיאור ארוך מדי');
      }
      if (product.variants.length > 8) {
        warnings.add('${product.productName} - יותר מ-8 וריאציות');
      }
    }
    
    final canFit = totalEstimatedHeight <= _AVAILABLE_HEIGHT;
    final utilizationPercentage = (totalEstimatedHeight / _AVAILABLE_HEIGHT * 100).clamp(0.0, 200.0);
    
    return PdfPageCapacity(
      canFitInSinglePage: canFit,
      estimatedHeight: totalEstimatedHeight,
      availableHeight: _AVAILABLE_HEIGHT,
      utilizationPercentage: utilizationPercentage,
      productHeights: productHeights,
      warnings: warnings,
    );
  }
  
  static double _estimateProductHeight(Product product) {
    // FIXED: Use same logic as PDF generation without extra margins
    if (product.hasVariants) {
      double baseHeight = 140.0;
      double variantsHeight = 0.0;
      
      final variantRows = product.variants.length;
      final headerHeight = 22.0;
      final rowHeight = 22.0;
      final footerHeight = product.variants.any((v) => 
          v.additionalNotes != null && v.additionalNotes!.isNotEmpty) ? 22.0 : 0.0;
      final padding = 20.0;
      
      variantsHeight = headerHeight + (variantRows * rowHeight) + footerHeight + padding;
      variantsHeight = variantsHeight.clamp(0.0, 180.0);
      
      return (baseHeight + variantsHeight).clamp(180.0, 400.0);
    } else {
      return 180.0;
    }
  }
}

class PdfPageCapacity {
  final bool canFitInSinglePage;
  final double estimatedHeight;
  final double availableHeight;
  final double utilizationPercentage;
  final List<double> productHeights;
  final List<String> warnings;
  
  const PdfPageCapacity({
    required this.canFitInSinglePage,
    required this.estimatedHeight,
    required this.availableHeight,
    required this.utilizationPercentage,
    required this.productHeights,
    required this.warnings,
  });
  
  String get statusText {
    if (canFitInSinglePage) {
      if (utilizationPercentage < 50) {
        return 'מקום רב';
      } else if (utilizationPercentage < 80) {
        return 'מתאים';
      } else {
        return 'כמעט מלא';
      }
    } else {
      return 'חורג מעמוד';
    }
  }
  
  Color get statusColor {
    if (canFitInSinglePage) {
      if (utilizationPercentage < 50) {
        return Colors.green;
      } else if (utilizationPercentage < 80) {
        return Colors.blue;
      } else {
        return Colors.orange;
      }
    } else {
      return Colors.red;
    }
  }
  
  IconData get statusIcon {
    if (canFitInSinglePage) {
      if (utilizationPercentage < 50) {
        return Icons.check_circle;
      } else if (utilizationPercentage < 80) {
        return Icons.info;
      } else {
        return Icons.warning;
      }
    } else {
      return Icons.error;
    }
  }
}