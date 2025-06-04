import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:a_s_office_web/model/ImageUtils.dart';

class PdfService {
  static pw.Font? _hebrewFont;
  static pw.Font? _hebrewFontBold;

  // Load Hebrew fonts with better error handling
  static Future<void> _loadHebrewFonts() async {
    if (_hebrewFont == null) {
      try {
        // Try to use Google Fonts for Hebrew
        _hebrewFont = await PdfGoogleFonts.notoSansHebrewRegular();
        _hebrewFontBold = await PdfGoogleFonts.notoSansHebrewBold();
        print('Hebrew fonts loaded successfully from Google Fonts');
      } catch (e) {
        print('Could not load Hebrew fonts: $e');
        // Fallback to basic fonts that support some Hebrew characters
        _hebrewFont = pw.Font.helvetica();
        _hebrewFontBold = pw.Font.helveticaBold();
        print('Using fallback fonts');
      }
    }
  }

  static Future<void> generateCatalogPdf(List<Product> allProducts, BuildContext context) async {
    try {
      // Load Hebrew fonts first
      await _loadHebrewFonts();
      
      final pdf = pw.Document();
      
      // Group products by page and sort
      final Map<int, List<Product>> productsByPage = {};
      for (final product in allProducts) {
        if (!productsByPage.containsKey(product.pageNumber)) {
          productsByPage[product.pageNumber] = [];
        }
        productsByPage[product.pageNumber]!.add(product);
      }
      
      // Sort products within each page by row
      productsByPage.forEach((pageNum, products) {
        products.sort((a, b) => a.rowInPage.compareTo(b.rowInPage));
      });
      
      // Sort pages
      final sortedPageNumbers = productsByPage.keys.toList()..sort();
      
      // Create one PDF page for each catalog page
      for (final pageNum in sortedPageNumbers) {
        final pageProducts = productsByPage[pageNum] ?? [];
        
        // Pre-load all images for this page
        final productImages = <Product, pw.ImageProvider?>{};
        for (final product in pageProducts) {
          productImages[product] = await _loadImageFromUrl(product.imagePath);
        }
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return _buildSinglePdfPage(pageProducts, pageNum, productImages);
            },
          ),
        );
      }
      
      // Use printing package for Windows/Desktop
      await _savePdfWithPrinting(pdf, context);
    } catch (e) {
      print('Error in generateCatalogPdf: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת הקטלוג: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Build a single page layout (one catalog page per PDF page)
  static pw.Widget _buildSinglePdfPage(
    List<Product> products, 
    int pageNum, 
    Map<Product, pw.ImageProvider?> productImages,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Page header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              // Remove borderRadius and non-uniform border to fix the error
            ),
            child: pw.Text(
              'Page $pageNum',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: _hebrewFontBold,
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          // Add a separator line instead
          pw.Container(
            width: double.infinity,
            height: 2,
            color: PdfColors.blue300,
          ),
          // Products list
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: products.isEmpty 
                ? pw.Center(
                    child: pw.Text(
                      'No products on this page',
                      style: pw.TextStyle(
                        font: _hebrewFont,
                        color: PdfColors.grey400,
                        fontSize: 16,
                      ),
                    ),
                  )
                : pw.ListView(
                    children: products.map((product) => 
                      _buildProductCardWithHeight(product, productImages[product])
                    ).toList(),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // Load image from URL and return as pw.ImageProvider
  static Future<pw.ImageProvider?> _loadImageFromUrl(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !ImageUtils.isValidImageUrl(imageUrl)) {
        return null;
      }

      final convertedUrl = ImageUtils.convertGoogleDriveUrl(imageUrl);
      final response = await http.get(Uri.parse(convertedUrl));
      
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Error loading image from URL: $e');
    }
    return null;
  }

  // New method that respects product height and includes actual images
  static pw.Widget _buildProductCardWithHeight(Product product, pw.ImageProvider? productImage) {
    // Convert the product height from app units to PDF points
    final pdfHeight = (product.height * 0.75); // Adjust this ratio as needed
    
    return pw.Container(
      height: pdfHeight,
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.white,
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey200,
            offset: const PdfPoint(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Content (right side in RTL)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Product name
                    pw.Text(
                      product.productName,
                      style: pw.TextStyle(
                        font: _hebrewFontBold,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 6),
                    // Description
                    if (product.description.isNotEmpty)
                      pw.Text(
                        product.description,
                        style: pw.TextStyle(
                          font: _hebrewFont,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                        maxLines: 4,
                      ),
                  ],
                ),
                // Product ID and Price (at bottom)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ID: ${product.productID}',
                      style: pw.TextStyle(
                        font: _hebrewFont,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      product.productPrice > 0 
                          ? '\$${product.productPrice.toStringAsFixed(0)}'
                          : 'Price on request',
                      style: pw.TextStyle(
                        font: _hebrewFontBold,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: product.productPrice > 0 ? PdfColors.blue700 : PdfColors.orange700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Image section (left side in RTL)
          _buildImageSection(productImage, pdfHeight),
        ],
      ),
    );
  }

  // Build image section with proper error handling
  static pw.Widget _buildImageSection(pw.ImageProvider? productImage, double cardHeight) {
    final imageHeight = cardHeight * 0.8;
    final imageWidth = 80.0;
    
    if (productImage != null) {
      // Show actual image
      return pw.Container(
        width: imageWidth,
        height: imageHeight,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.ClipRRect(
          child: pw.Image(
            productImage,
            fit: pw.BoxFit.cover,
            width: imageWidth,
            height: imageHeight,
          ),
        ),
      );
    } else {
      // Show placeholder
      return pw.Container(
        width: imageWidth,
        height: imageHeight,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 24,
                height: 24,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey400,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'IMG',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'No Image',
                style: pw.TextStyle(
                  font: _hebrewFont,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Desktop/Windows PDF generation using printing package
  static Future<void> _savePdfWithPrinting(pw.Document pdf, BuildContext context) async {
    try {
      final bytes = await pdf.save();
      
      // Show print preview dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error with printing package: $e');
      // Fallback to saving file directly
      await _saveToFile(pdf, context);
    }
  }

  // Alternative: Save PDF directly to file system
  static Future<void> _saveToFile(pw.Document pdf, BuildContext context) async {
    try {
      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'catalog_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error saving PDF to file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}