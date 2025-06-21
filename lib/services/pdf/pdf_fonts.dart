import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfFonts {
  static pw.Font? _hebrewFont;
  static pw.Font? _hebrewFontBold;

  static pw.Font? get hebrewFont => _hebrewFont;
  static pw.Font? get hebrewFontBold => _hebrewFontBold;

  static Future<void> loadHebrewFonts() async {
    if (_hebrewFont == null) {
      try {
        print('Loading Hebrew fonts...');
        _hebrewFont = await PdfGoogleFonts.notoSansHebrewRegular();
        _hebrewFontBold = await PdfGoogleFonts.notoSansHebrewBold();
        print('Hebrew fonts loaded successfully from Google Fonts');
      } catch (e) {
        print('Could not load Hebrew fonts: $e');
        _hebrewFont = pw.Font.helvetica();
        _hebrewFontBold = pw.Font.helveticaBold();
        print('Using fallback fonts');
      }
    }
  }
}