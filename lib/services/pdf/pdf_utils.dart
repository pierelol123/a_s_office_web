import 'package:pdf/pdf.dart';

class PdfUtils {
  static PdfColor parseColorHex(String hexColor) {
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        final r = int.parse(cleanHex.substring(0, 2), radix: 16);
        final g = int.parse(cleanHex.substring(2, 4), radix: 16);
        final b = int.parse(cleanHex.substring(4, 6), radix: 16);
        return PdfColor.fromInt((0xFF << 24) | (r << 16) | (g << 8) | b);
      }
      return PdfColors.grey400;
    } catch (e) {
      print('Error parsing color hex for PDF: $hexColor, error: $e');
      return PdfColors.grey400;
    }
  }
}