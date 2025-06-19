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
import 'package:flutter/foundation.dart' show kIsWeb; // Add this import

class PdfService {
  static pw.Font? _hebrewFont;
  static pw.Font? _hebrewFontBold;

  // Get the app directory path (same as ProductService)
  static Future<String> _getAppDirectoryPath() async {
    if (kIsWeb) {
      throw Exception('Web platform does not support local file storage');
    }
    
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/ASOfficeWeb');
    
    // Create app directory if it doesn't exist
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
      print('Created app directory: ${appDir.path}');
    }
    
    return appDir.path;
  }

  // Load Hebrew fonts with better error handling
  static Future<void> _loadHebrewFonts() async {
    if (_hebrewFont == null) {
      try {
        print('Loading Hebrew fonts...');
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
      print('=== STARTING PDF GENERATION ===');
      print('Total products: ${allProducts.length}');
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('יוצר PDF...'),
              ],
            ),
          );
        },
      );

      print('Step 1: Loading fonts...');
      await _loadHebrewFonts();
      print('Step 1: ✓ Fonts loaded');
      
      print('Step 2: Creating PDF document...');
      final pdf = pw.Document();
      print('Step 2: ✓ PDF document created');
      
      print('Step 3: Creating catalog intro...');
      final catalogIntro = CatalogIntro(
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
      print('Step 3: ✓ Catalog intro created');
      
      print('Step 4: Creating catalog index...');
      final catalogIndex = CatalogIndex.fromProducts(allProducts);
      print('Step 4: ✓ Catalog index created with ${catalogIndex.sections.length} sections');

      print('Step 5: Adding intro page...');
      try {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              print('Step 5a: Building intro page...');
              final result = _buildIntroPage(catalogIntro);
              print('Step 5a: ✓ Intro page built');
              return result;
            },
          ),
        );
        print('Step 5: ✓ Intro page added');
      } catch (e) {
        print('Step 5: ✗ Error adding intro page: $e');
        throw e;
      }

      print('Step 6: Adding index page...');
      try {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              print('Step 6a: Building index page...');
              final result = _buildIndexPage(catalogIndex);
              print('Step 6a: ✓ Index page built');
              return result;
            },
          ),
        );
        print('Step 6: ✓ Index page added');
      } catch (e) {
        print('Step 6: ✗ Error adding index page: $e');
        throw e;
      }

      print('Step 7: Processing products by page...');
      // Add product pages with timeout and error handling
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
      
      print('Step 8: Loading images for all pages...');
      
      // Load images with timeout and progress tracking
      for (final pageNum in sortedPageNumbers) {
        print('Step 8.$pageNum: Processing page $pageNum...');
        final pageProducts = productsByPage[pageNum] ?? [];
        print('Step 8.$pageNum: Found ${pageProducts.length} products on page $pageNum');
        
        // Load images with timeout
        final productImages = <Product, pw.ImageProvider?>{};
        for (int i = 0; i < pageProducts.length; i++) {
          final product = pageProducts[i];
          print('Step 8.$pageNum.$i: Loading image ${i + 1}/${pageProducts.length} for product: ${product.productName}');
          
          try {
            // Add timeout for image loading
            productImages[product] = await _loadImageFromUrl(product.imagePath)
                .timeout(const Duration(seconds: 10));
            print('Step 8.$pageNum.$i: ✓ Image loaded for ${product.productName}');
          } catch (e) {
            print('Step 8.$pageNum.$i: ✗ Timeout/error loading image for ${product.productName}: $e');
            productImages[product] = null; // Will show placeholder
          }
        }
        
        print('Step 9.$pageNum: Adding PDF page $pageNum to document...');
        try {
          print('Step 9.$pageNum.a: Creating page widget...');
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) {
                print('Step 9.$pageNum.b: Building single PDF page...');
                try {
                  final result = _buildSinglePdfPage(pageProducts, pageNum, productImages);
                  print('Step 9.$pageNum.b: ✓ Single PDF page built successfully');
                  return result;
                } catch (e) {
                  print('Step 9.$pageNum.b: ✗ Error building single PDF page: $e');
                  rethrow;
                }
              },
            ),
          );
          print('Step 9.$pageNum: ✓ PDF page $pageNum added successfully');
        } catch (e) {
          print('Step 9.$pageNum: ✗ Error adding PDF page $pageNum: $e');
          throw e;
        }
      }

      print('Step 10: All pages processed successfully');
      print('Step 11: Closing loading dialog...');
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        print('Step 11: ✓ Loading dialog closed');
      }
      
      print('Step 12: Showing PDF preview...');
      // Show PDF preview with options
      if (context.mounted) {
        try {
          await _showPdfPreviewDialog(pdf, context);
          print('Step 12: ✓ PDF preview shown');
        } catch (e) {
          print('Step 12: ✗ Error showing PDF preview: $e');
          throw e;
        }
      }
      
      print('=== PDF GENERATION COMPLETED SUCCESSFULLY ===');
    } catch (e) {
      print('=== ERROR IN PDF GENERATION ===');
      print('Error details: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Close loading dialog if still open
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

  // Load image from URL with timeout and better error handling
  static Future<pw.ImageProvider?> _loadImageFromUrl(String imageUrl) async {
    try {
      print('    Loading image from URL: $imageUrl');
      
      if (imageUrl.isEmpty) {
        print('    Empty image URL, returning null');
        return null;
      }
      
      if (!ImageUtils.isValidImageUrl(imageUrl)) {
        print('    Invalid image URL format, returning null');
        return null;
      }

      final convertedUrl = ImageUtils.convertGoogleDriveUrl(imageUrl);
      print('    Converted URL: $convertedUrl');
      
      // Add timeout for HTTP request
      final response = await http.get(Uri.parse(convertedUrl))
          .timeout(const Duration(seconds: 5));
      
      print('    HTTP response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('    Image loaded successfully, size: ${response.bodyBytes.length} bytes');
        return pw.MemoryImage(response.bodyBytes);
      } else {
        print('    HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('    Error loading image from URL: $e');
      return null;
    }
  }

  // Show PDF preview dialog with print and save options
  static Future<void> _showPdfPreviewDialog(pw.Document pdf, BuildContext context) async {
    try {
      print('Step 12.1: Generating PDF bytes for preview...');
      final bytes = await pdf.save();
      print('Step 12.1: ✓ PDF bytes generated: ${bytes.length} bytes');
      
      // Skip the problematic PdfPreview widget and go straight to action dialog
      print('Step 12.2: Showing simplified PDF dialog (bypassing PdfPreview)...');
      await _showSimplePdfDialog(pdf, context);
      print('Step 12.2: ✓ Simple PDF dialog shown');
    } catch (e) {
      print('Step 12: ✗ Error showing PDF preview: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהצגת התצוגה המקדימה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this simple PDF dialog method
  static Future<void> _showSimplePdfDialog(pw.Document pdf, BuildContext context) async {
    try {
      final bytes = await pdf.save();
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          print('Step 12.3: Building simple PDF success dialog...');
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Success message
                  const Text(
                    'PDF נוצר בהצלחה!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // File info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'פרטי הקובץ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'גודל הקובץ: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'נוצר: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // What would you like to do text
                  const Text(
                    'מה ברצונך לעשות?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Column(
                    children: [
                      // Save button (now primary action)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _saveToAppFolder(pdf, context);
                          },
                          icon: const Icon(Icons.download, size: 24),
                          label: Text(
                            kIsWeb ? 'הורד קובץ' : 'שמור בתיקיית האפליקציה',
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Two buttons in a row
                      Row(
                        children: [
                          // Print button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _printPdf(pdf, context);
                              },
                              icon: const Icon(Icons.print),
                              label: const Text('הדפס'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Print & Save button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _printAndSave(pdf, context);
                              },
                              icon: const Icon(Icons.print_outlined),
                              label: const Text('הדפס ושמור'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Close button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'סגור',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
      print('Step 12.3: ✓ Simple PDF dialog shown successfully');
    } catch (e) {
      print('Error showing simple PDF dialog: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהצגת הדיאלוג: $e'),
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
    print('      Building single PDF page for page $pageNum with ${products.length} products');
    
    try {
      final result = pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            // Page header - slightly bigger
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 16), // Increased from 12 to 16
              decoration: pw.BoxDecoration(
                color: PdfColors.blue100,
              ),
              child: pw.Text(
                'עמוד $pageNum',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: _hebrewFontBold,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18, // Increased from 16 to 18
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
            // Add a separator line
            pw.Container(
              width: double.infinity,
              height: 2,
              color: PdfColors.blue300,
            ),
            // Products list with more padding
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(16), // Increased from 12 to 16
                child: products.isEmpty 
                  ? pw.Center(
                      child: pw.Text(
                        'אין מוצרים בעמוד זה',
                        style: pw.TextStyle(
                          font: _hebrewFont,
                          color: PdfColors.grey400,
                          fontSize: 18, // Increased from 16 to 18
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    )
                  : pw.ListView(
                      children: products.map((product) {
                        print('        Building product card for: ${product.productName}');
                        try {
                          final productCard = _buildProductCardWithHeight(product, productImages[product]);
                          print('        ✓ Product card built for: ${product.productName}');
                          return productCard;
                        } catch (e) {
                          print('        ✗ Error building product card for ${product.productName}: $e');
                          rethrow;
                        }
                      }).toList(),
                    ),
              ),
            ),
          ],
        ),
      );
      
      print('      ✓ Single PDF page built successfully for page $pageNum');
      return result;
    } catch (e) {
      print('      ✗ Error building single PDF page for page $pageNum: $e');
      rethrow;
    }
  }

  // In the _buildProductCardWithHeight method, increase the height calculation:
  static pw.Widget _buildProductCardWithHeight(Product product, pw.ImageProvider? productImage) {
    print('        Building product card with height for: ${product.productName}');
    
    try {
      // Convert the product height from app units to PDF points and make it 30% bigger
      final pdfHeight = (product.height * 0.75 * 1.3); // Changed from 0.75 to 0.75 * 1.3 (30% increase)
      
      final result = pw.Container(
        height: pdfHeight,
        margin: const pw.EdgeInsets.only(bottom: 16), // Slightly increased margin too
        padding: const pw.EdgeInsets.all(16), // Increased padding from 12 to 16
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
                      // Product name - increased font size
                      pw.Text(
                        product.productName,
                        style: pw.TextStyle(
                          font: _hebrewFontBold,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16, // Increased from 14 to 16
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 8), // Increased from 6 to 8
                      // Description - increased font size
                      if (product.description.isNotEmpty)
                        pw.Text(
                          product.description,
                          style: pw.TextStyle(
                            font: _hebrewFont,
                            fontSize: 12, // Increased from 10 to 12
                            color: PdfColors.grey700,
                          ),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                          maxLines: 5, // Increased from 4 to 5 lines
                        ),
                      // SKU (if available) - Add SKU display
                      if (product.productSku != null && product.productSku!.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'מק״ט: ${product.productSku}',
                          style: pw.TextStyle(
                            font: _hebrewFont,
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                        ),
                      ],
                    ],
                  ),
                  // Product ID and Price (at bottom) - increased spacing and font sizes
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Product ID - increased font size
                      pw.Text(
                        'ID: ${product.productID}', // Changed from מק״ט to ID
                        style: pw.TextStyle(
                          font: _hebrewFont,
                          fontSize: 11, // Increased from 9 to 11
                          color: PdfColors.grey600,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      // Price - increased font size
                      pw.Text(
                        product.productPrice > 0 
                            ? '₪${product.productPrice.toStringAsFixed(0)}'
                            : 'מחיר לפי פנייה',
                        style: pw.TextStyle(
                          font: _hebrewFontBold,
                          fontSize: 14, // Increased from 12 to 14
                          fontWeight: pw.FontWeight.bold,
                          color: product.productPrice > 0 ? PdfColors.blue700 : PdfColors.orange700,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16), // Increased spacing from 12 to 16
            // Image section (left side in RTL) - make image bigger too
            _buildImageSection(productImage, pdfHeight),
          ],
        ),
      );
      
      print('        ✓ Product card with height built for: ${product.productName}');
      return result;
    } catch (e) {
      print('        ✗ Error building product card for ${product.productName}: $e');
      rethrow;
    }
  }

  // Also update the _buildImageSection to make images proportionally bigger:
  static pw.Widget _buildImageSection(pw.ImageProvider? productImage, double cardHeight) {
    final imageHeight = cardHeight * 0.8;
    final imageWidth = 104.0; // Increased from 80.0 to 104.0 (30% bigger)
    
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
      // Show placeholder - also bigger
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
                width: 32, // Increased from 24 to 32
                height: 32, // Increased from 24 to 32
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey400,
                  borderRadius: pw.BorderRadius.circular(6), // Increased from 4 to 6
                ),
                child: pw.Center(
                  child: pw.Text(
                    'IMG',
                    style: pw.TextStyle(
                      fontSize: 10, // Increased from 8 to 10
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 6), // Increased from 4 to 6
              pw.Text(
                'אין תמונה',
                style: pw.TextStyle(
                  font: _hebrewFont,
                  fontSize: 10, // Increased from 8 to 10
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

  // Print PDF using printing package
  static Future<void> _printPdf(pw.Document pdf, BuildContext context) async {
    try {
      final bytes = await pdf.save();
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הקטלוג נשלח להדפסה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error printing PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהדפסה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Print and save PDF
  static Future<void> _printAndSave(pw.Document pdf, BuildContext context) async {
    try {
      // First save the file
      await _saveToAppFolder(pdf, context);
      
      // Then print
      await _printPdf(pdf, context);
    } catch (e) {
      print('Error in print and save: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהדפסה ושמירה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Updated method to save PDF to app folder
  static Future<void> _saveToAppFolder(pw.Document pdf, BuildContext context) async {
    try {
      final bytes = await pdf.save();
      final timestamp = DateTime.now();
      final formattedTimestamp = '${timestamp.year}'
          '${timestamp.month.toString().padLeft(2, '0')}'
          '${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}'
          '${timestamp.minute.toString().padLeft(2, '0')}'
          '${timestamp.second.toString().padLeft(2, '0')}';
      
      final fileName = 'A_S_Office_Catalog_$formattedTimestamp.pdf';
      
      if (kIsWeb) {
        // For web platform - use browser download
        /*final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);*/
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('הקטלוג הורד בהצלחה: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'פתח תיקיית הורדות',
                textColor: Colors.white,
                onPressed: () {
                  // On web, we can't directly open the downloads folder
                  // but we can show instructions
                  _showWebDownloadInstructions(context, fileName);
                },
              ),
            ),
          );
        }
      } else {
        // For desktop/mobile - save to app directory (same as data files)
        final appDirectoryPath = await _getAppDirectoryPath();
        final file = File('$appDirectoryPath/$fileName');
        
        print('Saving PDF to app directory: ${file.path}');
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('הקטלוג נשמר בהצלחה!'),
                  SizedBox(height: 4),
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'תיקיית האפליקציה',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'פתח תיקייה',
                textColor: Colors.white,
                onPressed: () => _openAppFolder(context),
              ),
            ),
          );
        }
        
        print('PDF saved successfully to: ${file.path}');
        print('File size: ${await file.length()} bytes');
      }
    } catch (e) {
      print('Error saving PDF to app folder: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הקטלוג: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // New method to open app folder
  static Future<void> _openAppFolder(BuildContext context) async {
    try {
      if (kIsWeb) {
        return;
      }
      
      final appDirectoryPath = await _getAppDirectoryPath();
      
      // Open file explorer based on platform
      if (Platform.isWindows) {
        await Process.run('explorer', [appDirectoryPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [appDirectoryPath]);
      } else if (Platform.isLinux) {
        // Try different file managers
        try {
          await Process.run('xdg-open', [appDirectoryPath]);
        } catch (e) {
          try {
            await Process.run('nautilus', [appDirectoryPath]);
          } catch (e) {
            try {
              await Process.run('dolphin', [appDirectoryPath]);
            } catch (e) {
              throw Exception('לא ניתן לפתוח את סייר הקבצים');
            }
          }
        }
      }
    } catch (e) {
      print('Error opening app folder: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בפתיחת התיקייה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Alternative: Save PDF directly to file system (legacy method for compatibility)
  static Future<void> _saveToFile(pw.Document pdf, BuildContext context) async {
    await _saveToAppFolder(pdf, context); // Redirect to app folder method
  }

  // Add this method to show web download instructions
  static void _showWebDownloadInstructions(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'הקובץ הורד בהצלחה',
            textDirection: TextDirection.rtl,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'שם הקובץ: $fileName',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              const Text(
                'הקובץ נשמר בתיקיית ההורדות של הדפדפן שלך.\n\nלמציאת הקובץ:',
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              const Text(
                '• Chrome: Ctrl+J או לחץ על אייקון ההורדות\n'
                '• Firefox: Ctrl+Shift+Y או תפריט הורדות\n'
                '• Safari: Option+Cmd+L או הצג הורדות\n'
                '• Edge: Ctrl+J או תפריט הורדות',
                style: TextStyle(fontSize: 12),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('הבנתי'),
            ),
          ],
        );
      },
    );
  }

  // Add this method to open saved files on mobile/desktop
  static Future<void> _openSavedFile(String filePath, BuildContext context) async {
    try {
      if (kIsWeb) {
        // This shouldn't be called on web, but just in case
        return;
      }
      
      // For mobile/desktop - we'll try to open the file with the default PDF viewer
      // Note: This requires additional permissions and packages like open_file or url_launcher
      
      // For now, let's show the file location and copy it to clipboard
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'מיקום הקובץ',
              textDirection: TextDirection.rtl,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'הקובץ נשמר במיקום הבא:',
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    filePath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'העתק את הנתיב לעיל והדבק אותו בסייר הקבצים כדי לפתוח את הקובץ.',
                  style: TextStyle(fontSize: 12),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: filePath));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('הנתיב הועתק ללוח'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('העתק נתיב'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('סגור'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error opening file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בפתיחת הקובץ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static pw.Widget _buildIntroPage(CatalogIntro intro) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Title
        pw.Text(
          intro.title,
          style: pw.TextStyle(
            font: _hebrewFontBold,
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
            font: _hebrewFont,
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
            font: _hebrewFont,
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
            font: _hebrewFontBold,
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
                  style: pw.TextStyle(font: _hebrewFont, fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(width: 8),
              // Replace the checkmark symbol with a green circle
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
                  font: _hebrewFontBold,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                intro.contactInfo,
                style: pw.TextStyle(font: _hebrewFont, fontSize: 12),
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
            font: _hebrewFont,
            fontSize: 10,
            color: PdfColors.grey600,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  static pw.Widget _buildIndexPage(CatalogIndex catalogIndex) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Title
        pw.Text(
          'תוכן עניינים',
          style: pw.TextStyle(
            font: _hebrewFontBold,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 24),
        // Index entries
        _buildPdfIndexEntry('מבוא לקטלוג', 1),
        _buildPdfIndexEntry('תוכן עניינים', 2),
        pw.Divider(),
        ...catalogIndex.sections.map((section) => 
          _buildPdfIndexEntry(
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
                  font: _hebrewFontBold,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'סך הכל: ${catalogIndex.sections.fold(0, (sum, section) => sum + section.productCount)} מוצרים ב-${catalogIndex.sections.length} עמודים',
                style: pw.TextStyle(font: _hebrewFont, fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfIndexEntry(String title, int pageNum) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            pageNum.toString(),
            style: pw.TextStyle(
              font: _hebrewFontBold,
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
              style: pw.TextStyle(font: _hebrewFont, fontSize: 12),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}