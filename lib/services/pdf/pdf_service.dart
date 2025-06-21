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
import 'package:a_s_office_web/model/CatalogIntro.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import our split files
import 'pdf_fonts.dart';
import 'pdf_builders.dart';
import 'pdf_file_operations.dart';
import 'pdf_image_loader.dart';
import 'pdf_dialogs.dart';

class PdfService {
  // Main generation method
  static Future<void> generateCatalogPdf(List<Product> allProducts, BuildContext context) async {
    try {
      print('=== STARTING PDF GENERATION ===');
      print('Total products: ${allProducts.length}');
      
      // Show loading dialog
      PdfDialogs.showLoadingDialog(context);

      print('Step 1: Loading fonts...');
      await PdfFonts.loadHebrewFonts();
      print('Step 1: ✓ Fonts loaded');
      
      print('Step 2: Creating PDF document...');
      final pdf = pw.Document();
      print('Step 2: ✓ PDF document created');
      
      print('Step 3: Creating catalog intro...');
      final catalogIntro = _createCatalogIntro();
      print('Step 3: ✓ Catalog intro created');
      
      print('Step 4: Creating catalog index...');
      final catalogIndex = CatalogIndex.fromProducts(allProducts);
      print('Step 4: ✓ Catalog index created with ${catalogIndex.sections.length} sections');

      // Add intro page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => PdfBuilders.buildIntroPage(catalogIntro),
        ),
      );

      // Add index page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => PdfBuilders.buildIndexPage(catalogIndex),
        ),
      );

      // Process and add product pages
      await _processProductPages(pdf, allProducts);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show PDF preview
      if (context.mounted) {
        await PdfDialogs.showPdfPreviewDialog(pdf, context);
      }
      
      print('=== PDF GENERATION COMPLETED SUCCESSFULLY ===');
    } catch (e) {
      print('=== ERROR IN PDF GENERATION ===');
      print('Error details: $e');
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת הקטלוג: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods
  static CatalogIntro _createCatalogIntro() {
    return CatalogIntro(
      title: 'אמין סבאח \n ס.א ציוד משרדי ופרסום',
      subtitle: 'פתרונות מקצועיים לכל צרכי המשרד',
      description: 'ברוכים הבאים לקטלוג המוצרים שלנו. כאן תמצאו מגוון רחב של מוצרי משרד איכותיים במחירים תחרותיים.',
      features: [
        'מוצרים איכותיים ממותגים מובילים',
        'מתנות לעובדים וללקוחות',
        'מחירים תחרותיים',
        'משלוח מהיר',
        'שירות לקוחות מקצועי',
        'אחריות מלאה על כל המוצרים',
      ],
      contactInfo: 'טלפון: 0507715891 | אימייל: a.s.office.paper@gmail.com \n טלפון פקס: 04-6024177',
      lastUpdated: DateTime.now(),
    );
  }

  static Future<void> _processProductPages(pw.Document pdf, List<Product> allProducts) async {
    print('Step 7: Processing products by page...');
    
    final Map<int, List<Product>> productsByPage = {};
    for (final product in allProducts) {
      if (!productsByPage.containsKey(product.pageNumber)) {
        productsByPage[product.pageNumber] = [];
      }
      productsByPage[product.pageNumber]!.add(product);
    }
    
    productsByPage.forEach((pageNum, products) {
      products.sort((a, b) => a.rowInPage.compareTo(b.rowInPage));
    });
    
    final sortedPageNumbers = productsByPage.keys.toList()..sort();
    print('Step 7: ✓ Products organized into ${sortedPageNumbers.length} pages: $sortedPageNumbers');
    
    for (final pageNum in sortedPageNumbers) {
      final pageProducts = productsByPage[pageNum] ?? [];
      print('Processing page $pageNum with ${pageProducts.length} products');
      
      // Load images for this page
      final productImages = await PdfImageLoader.loadImagesForProducts(pageProducts);
      
      // Add PDF page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => PdfBuilders.buildSinglePdfPage(pageProducts, pageNum, productImages),
        ),
      );
    }
  }
}