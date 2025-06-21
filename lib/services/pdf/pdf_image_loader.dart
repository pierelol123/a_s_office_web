import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/model/ImageUtils.dart';

class PdfImageLoader {
  static Future<Map<Product, pw.ImageProvider?>> loadImagesForProducts(List<Product> products) async {
    final productImages = <Product, pw.ImageProvider?>{};
    
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      print('Loading image ${i + 1}/${products.length} for product: ${product.productName}');
      
      try {
        productImages[product] = await loadImageFromUrl(product.imagePath)
            .timeout(const Duration(seconds: 10));
        print('✓ Image loaded for ${product.productName}');
      } catch (e) {
        print('✗ Timeout/error loading image for ${product.productName}: $e');
        productImages[product] = null;
      }
    }
    
    return productImages;
  }

  static Future<pw.ImageProvider?> loadImageFromUrl(String imageUrl) async {
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
}