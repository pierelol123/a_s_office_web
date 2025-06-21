import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/model/CatalogIntro.dart';
import 'pdf_fonts.dart';
import 'pdf_product_card.dart';

class PdfBuilders {
  // PDF page constants for debugging
  static const double _PAGE_HEIGHT = 930.0; // A4 height in points
  static const double _PAGE_MARGIN = 5.0; // Margin on all sides
  static const double _PAGE_HEADER_HEIGHT = 20.0; // Page header space
  static const double _AVAILABLE_CONTENT_HEIGHT = _PAGE_HEIGHT - (_PAGE_MARGIN * 2) - _PAGE_HEADER_HEIGHT;

  static pw.Widget buildIntroPage(CatalogIntro intro) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Title
        pw.Text(
          intro.title,
          style: pw.TextStyle(
            font: PdfFonts.hebrewFontBold,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        // Subtitle
        pw.Text(
          intro.subtitle,
          style: pw.TextStyle(
            font: PdfFonts.hebrewFont,
            fontSize: 18,
          ),
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 24),
        // Description
        pw.Text(
          intro.description,
          style: pw.TextStyle(
            font: PdfFonts.hebrewFont,
            fontSize: 14,
          ),
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.right,
        ),
        pw.SizedBox(height: 24),
        // Features
        pw.Text(
          'מה אנחנו מציעים:',
          style: pw.TextStyle(
            font: PdfFonts.hebrewFontBold,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 12),
        ...intro.features.map((feature) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Text(
                  feature,
                  style: pw.TextStyle(font: PdfFonts.hebrewFont, fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                width: 12,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Container(
                    width: 6,
                    height: 6,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),
        pw.SizedBox(height: 24),
        // Contact info
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue100,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.blue300),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'צור קשר',
                style: pw.TextStyle(
                  font: PdfFonts.hebrewFontBold,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                intro.contactInfo,
                style: pw.TextStyle(font: PdfFonts.hebrewFont, fontSize: 12),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
        pw.Spacer(),
        // Last updated
        pw.Text(
          'עודכן לאחרונה: ${intro.lastUpdated.day}/${intro.lastUpdated.month}/${intro.lastUpdated.year}',
          style: pw.TextStyle(
            font: PdfFonts.hebrewFont,
            fontSize: 10,
            color: PdfColors.grey600,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  static pw.Widget buildIndexPage(CatalogIndex catalogIndex) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Title
        pw.Text(
          'תוכן עניינים',
          style: pw.TextStyle(
            font: PdfFonts.hebrewFontBold,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 24),
        // Index entries
        _buildIndexEntry('מבוא לקטלוג', 1),
        _buildIndexEntry('תוכן עניינים', 2),
        pw.Divider(),
        ...catalogIndex.sections.map((section) => 
          _buildIndexEntry(
            '${section.title} (${section.productCount} מוצרים)',
            section.pageNumber,
          ),
        ),
        pw.Spacer(),
        // Summary
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.green100,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.green300),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'סיכום הקטלוג',
                style: pw.TextStyle(
                  font: PdfFonts.hebrewFontBold,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'סך הכל: ${catalogIndex.sections.fold(0, (sum, section) => sum + section.productCount)} מוצרים ב-${catalogIndex.sections.length} עמודים',
                style: pw.TextStyle(font: PdfFonts.hebrewFont, fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget buildSinglePdfPage(
    List<Product> products, 
    int pageNum, 
    Map<Product, pw.ImageProvider?> productImages,
  ) {
    print('      Building single PDF page for page $pageNum with ${products.length} products');
    
    // ADDED: Calculate space requirements BEFORE building
    _analyzePageCapacity(products, pageNum);
    
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Products list with capacity tracking and flexible spacing
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: products.isEmpty 
                ? pw.Center(
                    child: pw.Text(
                      'אין מוצרים בעמוד זה',
                      style: pw.TextStyle(
                        font: PdfFonts.hebrewFont,
                        color: PdfColors.grey400,
                        fontSize: 18,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.right,
                    ),
                  )
                : _buildProductsListWithFlexibleSpacing(products, productImages, pageNum),
            ),
          ),
          // Separator line
          pw.Container(
            width: double.infinity,
            height: 2,
            color: PdfColors.blue300,
          ),
          // Page footer
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
            ),
            child: pw.Text(
              'עמוד $pageNum',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: PdfFonts.hebrewFontBold,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: New method to build products list with flexible spacing
  static pw.Widget _buildProductsListWithFlexibleSpacing(
    List<Product> products, 
    Map<Product, pw.ImageProvider?> productImages,
    int pageNum,
  ) {
    print('      DEBUG: Building products list with flexible spacing for page $pageNum');
    
    // Track cumulative height as we build each product
    double cumulativeHeight = 0.0;
    final productWidgets = <pw.Widget>[];
    final productHeights = <double>[];
    
    // First pass: Build all products that fit and track their heights
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      
      // Calculate estimated height for this product
      final estimatedProductHeight = _estimateProductHeight(product);
      final newCumulativeHeight = cumulativeHeight + estimatedProductHeight;
      
      print('      DEBUG: Product ${i + 1}/${products.length}: "${product.productName}"');
      print('      DEBUG: Estimated height: ${estimatedProductHeight.toStringAsFixed(1)}px');
      print('      DEBUG: Cumulative height: ${newCumulativeHeight.toStringAsFixed(1)}px');
      print('      DEBUG: Available space: ${_AVAILABLE_CONTENT_HEIGHT.toStringAsFixed(1)}px');
      
      // Check if this product will fit
      if (newCumulativeHeight <= _AVAILABLE_CONTENT_HEIGHT) {
        print('      DEBUG: ✓ Product FITS in page - adding to layout');
        productWidgets.add(
          PdfProductCard.buildProductCard(product, productImages[product])
        );
        productHeights.add(estimatedProductHeight);
        cumulativeHeight = newCumulativeHeight;
      } else {
        print('      DEBUG: ✗ Product DOES NOT FIT in page!');
        print('      DEBUG: Would exceed page by: ${(newCumulativeHeight - _AVAILABLE_CONTENT_HEIGHT).toStringAsFixed(1)}px');
        print('      DEBUG: SKIPPING product: "${product.productName}"');
        
        // Add warning message to PDF for skipped products
        productWidgets.add(
          _buildOverflowWarningWidget(products.sublist(i))
        );
        break; // Stop adding more products
      }
    }
    
    // Calculate available space for flexible distribution
    final usedHeight = productHeights.fold(0.0, (sum, height) => sum + height);
    final availableSpace = _AVAILABLE_CONTENT_HEIGHT - usedHeight;
    
    print('      DEBUG: Space utilization analysis:');
    print('      DEBUG: Products successfully added: ${productWidgets.length}/${products.length}');
    print('      DEBUG: Total height used by products: ${usedHeight.toStringAsFixed(1)}px');
    print('      DEBUG: Available space for distribution: ${availableSpace.toStringAsFixed(1)}px');
    print('      DEBUG: Space utilization: ${(usedHeight / _AVAILABLE_CONTENT_HEIGHT * 100).toStringAsFixed(1)}%');
    
    // Build layout with flexible spacing
    if (productWidgets.length <= 1) {
      // Single product or warning - center it
      return pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: productWidgets,
        ),
      );
    } else {
      // Multiple products - distribute them evenly
      return _buildFlexibleLayout(productWidgets, availableSpace);
    }
  }

  // ADDED: Method to build flexible layout with distributed spacing
  static pw.Widget _buildFlexibleLayout(List<pw.Widget> productWidgets, double availableSpace) {
    print('      DEBUG: Building flexible layout with ${productWidgets.length} products');
    print('      DEBUG: Available space for distribution: ${availableSpace.toStringAsFixed(1)}px');
    
    if (availableSpace <= 0) {
      // No extra space - use tight layout
      print('      DEBUG: No extra space - using tight layout');
      return pw.Column(
        children: productWidgets,
      );
    }
    
    // Calculate spacing strategy based on available space
    final spacingStrategy = _calculateSpacingStrategy(productWidgets.length, availableSpace);
    
    print('      DEBUG: Spacing strategy: ${spacingStrategy.type}');
    print('      DEBUG: Spacing between products: ${spacingStrategy.betweenProducts.toStringAsFixed(1)}px');
    print('      DEBUG: Top padding: ${spacingStrategy.topPadding.toStringAsFixed(1)}px');
    print('      DEBUG: Bottom padding: ${spacingStrategy.bottomPadding.toStringAsFixed(1)}px');
    
    // Build the layout based on strategy
    final children = <pw.Widget>[];
    
    // Add top padding if needed
    if (spacingStrategy.topPadding > 0) {
      //children.add(pw.SizedBox(height: spacingStrategy.topPadding));
    }
    
    // Add products with spacing
    for (int i = 0; i < productWidgets.length; i++) {
      children.add(productWidgets[i]);
      
      // Add spacing between products (except after last product)
      if (i < productWidgets.length - 1 && spacingStrategy.betweenProducts > 0) {
        children.add(pw.SizedBox(height: spacingStrategy.betweenProducts));
      }
    }
    
    // Add bottom padding if needed
    if (spacingStrategy.bottomPadding > 0) {
      children.add(pw.SizedBox(height: spacingStrategy.bottomPadding));
    }
    
    return pw.Column(
      mainAxisAlignment: spacingStrategy.mainAxisAlignment,
      children: children,
    );
  }

  // ADDED: Method to calculate optimal spacing strategy
  static _SpacingStrategy _calculateSpacingStrategy(int productCount, double availableSpace) {
    const double maxSpacingBetweenProducts = 40.0; // Maximum spacing between products
    const double maxPadding = 60.0; // Maximum top/bottom padding
    
    if (productCount <= 1) {
      // Single product - center it
      return _SpacingStrategy(
        type: 'center',
        betweenProducts: 0.0,
        topPadding: availableSpace / 2,
        bottomPadding: availableSpace / 2,
        mainAxisAlignment: pw.MainAxisAlignment.center,
      );
    }
    
    // Calculate ideal spacing between products
    final spacingSlots = productCount - 1; // Number of gaps between products
    final idealSpacingBetween = availableSpace / (spacingSlots + 2); // +2 for top/bottom padding
    
    if (idealSpacingBetween <= maxSpacingBetweenProducts) {
      // Distribute evenly with moderate spacing
      final betweenProducts = idealSpacingBetween;
      final padding = idealSpacingBetween;
      
      return _SpacingStrategy(
        type: 'even-distribution',
        betweenProducts: betweenProducts,
        topPadding: padding,
        bottomPadding: padding,
        mainAxisAlignment: pw.MainAxisAlignment.start,
      );
    } else {
      // Too much space - use maximum spacing and center the group
      final betweenProducts = maxSpacingBetweenProducts;
      final totalUsedForSpacing = betweenProducts * spacingSlots;
      final remainingForPadding = availableSpace - totalUsedForSpacing;
      final padding = (remainingForPadding / 2).clamp(0.0, maxPadding);
      
      return _SpacingStrategy(
        type: 'max-spacing-centered',
        betweenProducts: betweenProducts,
        topPadding: padding,
        bottomPadding: padding,
        mainAxisAlignment: pw.MainAxisAlignment.start,
      );
    }
  }

  // ADDED: Method to build overflow warning widget
  static pw.Widget _buildOverflowWarningWidget(List<Product> skippedProducts) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.orange400, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'אזהרה: מוצרים לא נכנסו לעמוד',
                style: pw.TextStyle(
                  font: PdfFonts.hebrewFontBold,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange500,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '!',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'המוצרים הבאים לא נכנסו בעמוד זה עקב מחסור במקום:',
            style: pw.TextStyle(
              font: PdfFonts.hebrewFont,
              fontSize: 12,
              color: PdfColors.orange700,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 4),
          ...skippedProducts.map((skippedProduct) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              '• ${skippedProduct.productName}',
              style: pw.TextStyle(
                font: PdfFonts.hebrewFont,
                fontSize: 11,
                color: PdfColors.orange600,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          )).toList(),
          pw.SizedBox(height: 8),
          pw.Text(
            'פתרון: העבר מוצרים לעמוד חדש או הקטן את התוכן',
            style: pw.TextStyle(
              font: PdfFonts.hebrewFont,
              fontSize: 10,
              color: PdfColors.orange600,
              fontStyle: pw.FontStyle.italic,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ADDED: Method to analyze page capacity before building
  static void _analyzePageCapacity(List<Product> products, int pageNum) {
    print('      DEBUG: ===== PAGE CAPACITY ANALYSIS =====');
    print('      DEBUG: Page number: $pageNum');
    print('      DEBUG: Number of products: ${products.length}');
    print('      DEBUG: Available content height: ${_AVAILABLE_CONTENT_HEIGHT.toStringAsFixed(1)}px');
    
    double totalEstimatedHeight = 0.0;
    
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final productHeight = _estimateProductHeight(product);
      totalEstimatedHeight += productHeight;
      
      print('      DEBUG: Product ${i + 1}: "${product.productName}"');
      print('      DEBUG: - Has variants: ${product.hasVariants}');
      print('      DEBUG: - Variant count: ${product.variants.length}');
      print('      DEBUG: - Estimated height: ${productHeight.toStringAsFixed(1)}px');
      print('      DEBUG: - Running total: ${totalEstimatedHeight.toStringAsFixed(1)}px');
    }
    
    print('      DEBUG: Total estimated height: ${totalEstimatedHeight.toStringAsFixed(1)}px');
    print('      DEBUG: Available height: ${_AVAILABLE_CONTENT_HEIGHT.toStringAsFixed(1)}px');
    
    if (totalEstimatedHeight > _AVAILABLE_CONTENT_HEIGHT) {
      final overflow = totalEstimatedHeight - _AVAILABLE_CONTENT_HEIGHT;
      print('      DEBUG: ⚠️  PAGE OVERFLOW DETECTED! ⚠️');
      print('      DEBUG: Overflow amount: ${overflow.toStringAsFixed(1)}px');
      print('      DEBUG: Utilization: ${(totalEstimatedHeight / _AVAILABLE_CONTENT_HEIGHT * 100).toStringAsFixed(1)}%');
      
      // Calculate how many products might fit
      double runningHeight = 0.0;
      int fittingProducts = 0;
      
      for (int i = 0; i < products.length; i++) {
        final productHeight = _estimateProductHeight(products[i]);
        if (runningHeight + productHeight <= _AVAILABLE_CONTENT_HEIGHT) {
          runningHeight += productHeight;
          fittingProducts++;
        } else {
          break;
        }
      }
      
      print('      DEBUG: Estimated products that will fit: $fittingProducts/${products.length}');
      print('      DEBUG: Products likely to be cut off: ${products.length - fittingProducts}');
    } else {
      final availableSpace = _AVAILABLE_CONTENT_HEIGHT - totalEstimatedHeight;
      print('      DEBUG: ✅ ALL PRODUCTS SHOULD FIT');
      print('      DEBUG: Utilization: ${(totalEstimatedHeight / _AVAILABLE_CONTENT_HEIGHT * 100).toStringAsFixed(1)}%');
      print('      DEBUG: Available space for distribution: ${availableSpace.toStringAsFixed(1)}px');
    }
    
    print('      DEBUG: ======================================');
  }

  // ADDED: Method to estimate product height (matches your PDF product card logic)
  static double _estimateProductHeight(Product product) {
    // Using the same logic as PdfProductCard.buildProductCard
    if (product.hasVariants) {
      // Products WITH variants
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
      
      final height = (baseHeight + variantsHeight).clamp(180.0, 400.0);
      
      // Add margin
      return height + 20.0; // bottom margin
    } else {
      // Products WITHOUT variants
      return 180.0 + 20.0; // height + margin
    }
  }

  static pw.Widget _buildIndexEntry(String title, int pageNum) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            pageNum.toString(),
            style: pw.TextStyle(
              font: PdfFonts.hebrewFontBold,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 16),
              child: pw.Row(
                children: List.generate(20, (index) => pw.Expanded(
                  child: pw.Container(
                    height: 1,
                    color: index.isEven ? PdfColors.grey300 : const PdfColor(0, 0, 0, 0),
                  ),
                )),
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              title,
              style: pw.TextStyle(font: PdfFonts.hebrewFont, fontSize: 12),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ADDED: Helper class for spacing strategy
class _SpacingStrategy {
  final String type;
  final double betweenProducts;
  final double topPadding;
  final double bottomPadding;
  final pw.MainAxisAlignment mainAxisAlignment;
  
  const _SpacingStrategy({
    required this.type,
    required this.betweenProducts,
    required this.topPadding,
    required this.bottomPadding,
    required this.mainAxisAlignment,
  });
}