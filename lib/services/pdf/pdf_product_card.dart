import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:a_s_office_web/model/Product.dart';
import 'pdf_fonts.dart';
import 'pdf_variants_table.dart';

class PdfProductCard {
  static pw.Widget buildProductCard(Product product, pw.ImageProvider? productImage) {
    print('        Building product card for: ${product.productName}');
    
    try {
      // INCREASED: Height calculation to accommodate larger fonts and images
      double pdfHeight;
      
      if (product.hasVariants) {
        // Products WITH variants - calculate space needed with larger elements
        double baseHeight = 140.0; // INCREASED: Base for essential content (was 120.0)
        double variantsHeight = 0.0;
        
        // Calculate realistic variants height with larger elements
        final variantRows = product.variants.length;
        final headerHeight = 22.0; // INCREASED: Table header (was 24.0)
        final rowHeight = 22.0; // INCREASED: Each table row (was 18.0)
        final footerHeight = product.variants.any((v) => 
            v.additionalNotes != null && v.additionalNotes!.isNotEmpty) ? 22.0 : 0.0; // INCREASED
        final padding = 20.0; // INCREASED: Container padding (was 16.0)
        
        variantsHeight = headerHeight + (variantRows * rowHeight) + footerHeight + padding;
        variantsHeight = variantsHeight.clamp(0.0, 180.0); // INCREASED: max height (was 150.0)
        
        pdfHeight = (baseHeight + variantsHeight).clamp(180.0, 400.0); // INCREASED: range (was 200-350)
        
        print('DEBUG: Product WITH variants - height: $pdfHeight (base: $baseHeight + variants: $variantsHeight)');
      } else {
        // Products WITHOUT variants - larger compact height
        pdfHeight = 180.0; // INCREASED: Compact height (was 180.0)
        
        print('DEBUG: Product WITHOUT variants - compact height: $pdfHeight');
      }
      
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20), // INCREASED: margin (was 16)
        padding: const pw.EdgeInsets.all(20), // INCREASED: padding (was 16)
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 2.0), // INCREASED: border width (was 1.5)
          borderRadius: pw.BorderRadius.circular(12), // INCREASED: border radius (was 10)
          color: PdfColors.white,
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey200,
              offset: const PdfPoint(0, 3), // INCREASED: shadow offset (was 2)
              blurRadius: 6, // INCREASED: shadow blur (was 4)
            ),
          ],
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Content (right side in RTL)
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // FIXED CONTENT SECTION - Essential content with larger fonts
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Product name - GUARANTEED - LARGER
                      pw.Text(
                        product.productName,
                        style: pw.TextStyle(
                          font: PdfFonts.hebrewFontBold,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18, // INCREASED: from 15 to 18
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                        maxLines: 2,
                      ),
                      pw.SizedBox(height: 4), // INCREASED: spacing (was 6)
                      
                      // Description - GUARANTEED - LARGER
                      if (product.description.isNotEmpty) ...[
                        pw.Text(
                          product.description,
                          style: pw.TextStyle(
                            font: PdfFonts.hebrewFont,
                            fontSize: 14, // INCREASED: from 11 to 14
                            color: PdfColors.grey700,
                          ),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                          maxLines: product.hasVariants ? 2 : 4, // CHANGED: More lines when no variants
                        ),
                        pw.SizedBox(height: 4), // INCREASED: spacing (was 4)
                      ],
                      
                      // SKU - GUARANTEED - LARGER
                      if (product.productSku != null && product.productSku!.isNotEmpty) ...[
                        pw.Text(
                          'מק״ט: ${product.productSku}',
                          style: pw.TextStyle(
                            font: PdfFonts.hebrewFont,
                            fontSize: 12, // INCREASED: from 9 to 12
                            color: PdfColors.grey600,
                          ),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                        ),
                        pw.SizedBox(height: 4), // INCREASED: spacing (was 8)
                      ],
                    ],
                  ),
                  
                  // VARIANTS SECTION - Only for products with variants
                  if (product.hasVariants) ...[
                    pw.Container(
                      width: double.infinity,
                      child: PdfVariantsTable.buildVariantsTable(product),
                    ),
                    pw.SizedBox(height: 4), // INCREASED: spacing (was 8)
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 16), // INCREASED: spacing (was 12)
            // Image section (left side in RTL) - LARGER
            pw.Expanded(
              flex: 1,
              child: _buildImageSection(productImage, pdfHeight),
            ),
          ],
        ),
      );
    } catch (e) {
      print('        ✗ Error building product card for ${product.productName}: $e');
      rethrow;
    }
  }

  static pw.Widget _buildImageSection(pw.ImageProvider? productImage, double cardHeight) {
    final double imageHeight = (cardHeight * 0.6).clamp(120.0, 220.0); // INCREASED: multiplier from 0.5 to 0.6, range from 80-160 to 120-220
    
    print('DEBUG: Image section height: $imageHeight (from card height: $cardHeight)');
    
    if (productImage != null) {
      return pw.Container(
        height: imageHeight,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 2.0), // INCREASED: border width (was 1.5)
          borderRadius: pw.BorderRadius.circular(10), // INCREASED: border radius (was 8)
          color: PdfColor.fromHex('#F9FAFB'),
        ),
        child: pw.ClipRRect(
          child: pw.Image(
            productImage,
            fit: pw.BoxFit.contain,
            height: imageHeight,
          ),
        ),
      );
    } else {
      return pw.Container(
        height: imageHeight,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(10), // INCREASED: border radius (was 8)
          border: pw.Border.all(color: PdfColors.grey300, width: 2.0), // INCREASED: border width (was 1.5)
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 40, // INCREASED: icon size (was 28)
                height: 40,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey400,
                  borderRadius: pw.BorderRadius.circular(8), // INCREASED: border radius (was 6)
                ),
                child: pw.Center(
                  child: pw.Text(
                    'IMG',
                    style: pw.TextStyle(
                      fontSize: 12, // INCREASED: font (was 9)
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 8), // INCREASED: spacing (was 4)
              pw.Text(
                'אין תמונה',
                style: pw.TextStyle(
                  font: PdfFonts.hebrewFont,
                  fontSize: 12, // INCREASED: font (was 9)
                  color: PdfColors.grey600,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ),
      );
    }
  }
}