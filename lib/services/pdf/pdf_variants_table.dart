import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:a_s_office_web/model/Product.dart';
import 'pdf_fonts.dart';
import 'pdf_utils.dart';

class PdfVariantsTable {
  static pw.Widget buildVariantsTable(Product product) {
    print('DEBUG: buildVariantsTable called for product: ${product.productName}');
    print('DEBUG: Product has variants: ${product.hasVariants}');
    print('DEBUG: Number of variants: ${product.variants.length}');
    
    if (product.variants.isNotEmpty) {
      print('DEBUG: First variant - SKU: ${product.variants.first.sku}, Color: ${product.variants.first.color}');
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.SizedBox(height: 6),
        // Compact table container
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F3F4F6'),
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE'), width: 0.5),
          ),
          child: pw.Column(
            children: [
              // Table header
              _buildTableHeader(),
              // Table rows - KEEP ALL VARIANTS IN TABLE FORMAT
              ..._buildTableRows(product),
              // Notes footer if needed
              if (product.variants.any((v) => 
                  v.additionalNotes != null && v.additionalNotes!.isNotEmpty))
                _buildNotesFooter(),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader() {
    print('DEBUG: Building table header');
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), // KEEP INCREASED padding
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#DBEAFE'),
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(4), // KEEP INCREASED border radius
          topRight: pw.Radius.circular(4),
        ),
      ),
      child: pw.Row(
        children: [
          // SKU Column Header (rightmost)
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'מק״ט',
              style: pw.TextStyle(
                font: PdfFonts.hebrewFontBold ?? PdfFonts.hebrewFont,
                fontSize: 11, // KEEP INCREASED font size
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1E40AF'),
              ),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          // Divider
          pw.Container(
            width: 1, // KEEP INCREASED divider width
            height: 12, // KEEP INCREASED divider height
            color: PdfColor.fromHex('#93C5FD'),
          ),
          // Color Column Header (leftmost)
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'גוון',
              style: pw.TextStyle(
                font: PdfFonts.hebrewFontBold ?? PdfFonts.hebrewFont,
                fontSize: 11, // KEEP INCREASED font size
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1E40AF'),
              ),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  // CHANGED: Accept Product instead of limited variants list to show ALL variants
  static List<pw.Widget> _buildTableRows(Product product) {
    print('DEBUG: Building table rows for ${product.variants.length} variants');
    
    final rows = product.variants.asMap().entries.map((entry) {
      final index = entry.key;
      final variant = entry.value;
      final isLastRow = index == product.variants.length - 1;
      
      print('DEBUG: Building row $index - SKU: ${variant.sku}, Color: ${variant.color}, ColorHex: ${variant.colorHex}');

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3), // KEEP INCREASED padding
        decoration: pw.BoxDecoration(
          color: index % 2 == 0 
              ? PdfColors.white 
              : PdfColor.fromHex('#F3F4F6'),
          borderRadius: isLastRow 
              ? const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(4), // KEEP INCREASED border radius
                  bottomRight: pw.Radius.circular(4),
                ) 
              : null,
        ),
        child: pw.Row(
          children: [
            // SKU Column (rightmost)
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                variant.sku.isNotEmpty ? variant.sku : 'ללא מק״ט',
                style: pw.TextStyle(
                  font: PdfFonts.hebrewFont,
                  fontSize: 10, // KEEP INCREASED font size
                  color: variant.sku.isNotEmpty 
                      ? PdfColor.fromHex('#1D4ED8')
                      : PdfColors.grey500,
                  fontWeight: variant.sku.isNotEmpty 
                      ? pw.FontWeight.bold 
                      : pw.FontWeight.normal,
                ),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
                maxLines: 1, // Prevent overflow
                overflow: pw.TextOverflow.clip,
              ),
            ),
            // Divider
            pw.Container(
              width: 1, // KEEP INCREASED divider width
              height: 14, // KEEP INCREASED divider height
              color: PdfColor.fromHex('#BFDBFE'),
            ),
            // Color Column (leftmost)
            pw.Expanded(
              flex: 3,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Color name
                  pw.Flexible(
                    child: pw.Text(
                      variant.color,
                      style: pw.TextStyle(
                        font: PdfFonts.hebrewFont,
                        fontSize: 10, // KEEP INCREASED font size
                        color: PdfColor.fromHex('#1D4ED8'),
                        fontWeight: pw.FontWeight.normal,
                      ),
                      textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                      maxLines: 1, // Prevent overflow
                      overflow: pw.TextOverflow.clip,
                    ),
                  ),
                  // Color indicator
                  if (variant.colorHex != null && variant.colorHex!.isNotEmpty) ...[
                    pw.SizedBox(width: 4), // KEEP INCREASED spacing
                    pw.Container(
                      width: 8, // KEEP INCREASED color indicator size
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: PdfUtils.parseColorHex(variant.colorHex!),
                        borderRadius: pw.BorderRadius.circular(4), // KEEP INCREASED border radius
                        border: pw.Border.all(
                          color: PdfColors.grey400,
                          width: 0.5, // KEEP INCREASED border width
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
    
    print('DEBUG: Created ${rows.length} table rows');
    return rows;
  }

  static pw.Widget _buildNotesFooter() {
    print('DEBUG: Building notes footer');
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FEF3C7'),
        borderRadius: const pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(3),
          bottomRight: pw.Radius.circular(3),
        ),
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromHex('#F59E0B'), width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'הערות נוספות זמינות',
            style: pw.TextStyle(
              font: PdfFonts.hebrewFont,
              fontSize: 5,
              color: PdfColor.fromHex('#D97706'),
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(width: 2),
          pw.Container(
            width: 6,
            height: 6,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F59E0B'),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Center(
              child: pw.Text(
                'i',
                style: pw.TextStyle(
                  fontSize: 4,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}