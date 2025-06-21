import 'package:flutter/material.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/model/ImageUtils.dart';

// ========== TEXT SIZE CONFIGURATION ==========
// Normal Layout Text Sizes
const double _NORMAL_TITLE_SIZE = 20.0; // Increased from ~16
const double _NORMAL_DESCRIPTION_SIZE = 18.0; // Increased from ~12
const double _NORMAL_PRICE_SIZE = 16.0; // Increased from ~14
const double _NORMAL_ID_SIZE = 12.0; // Increased from ~10
const double _NORMAL_SKU_SIZE = 12.0; // New SKU size
const double _NORMAL_BUTTON_TEXT_SIZE = 14.0; // Increased from ~12
const double _NORMAL_ERROR_TEXT_SIZE = 12.0; // Increased from ~10
const double _NORMAL_LOADING_TEXT_SIZE = 12.0; // Increased from ~10
const double _NORMAL_PLACEHOLDER_TEXT_SIZE = 12.0; // Increased from ~10

// Compact Layout Text Sizes
const double _COMPACT_TITLE_SIZE = 25.0; // Increased from 14
const double _COMPACT_DESCRIPTION_SIZE = 16.0; // Increased from 11
const double _COMPACT_PRICE_SIZE = 14.0; // Increased from 12
const double _COMPACT_ID_SIZE = 12.0; // Increased from 10
const double _COMPACT_SKU_SIZE = 12.0; // New SKU size
const double _COMPACT_BUTTON_TEXT_SIZE = 13.0; // Increased from 11
const double _COMPACT_ERROR_TEXT_SIZE = 10.0; // Increased from 8
const double _COMPACT_LOADING_TEXT_SIZE = 10.0; // Increased from 8
const double _COMPACT_PLACEHOLDER_TEXT_SIZE = 10.0; // Increased from 8

// Icon Sizes
const double _NORMAL_ICON_SIZE = 50.0; // Increased from 16
const double _COMPACT_ICON_SIZE = 16.0; // Increased from 14
const double _NORMAL_ERROR_ICON_SIZE = 40.0; // Increased from 32
const double _COMPACT_ERROR_ICON_SIZE = 30.0; // Increased from 24
const double _NORMAL_PLACEHOLDER_ICON_SIZE = 40.0; // Increased from 32
const double _COMPACT_PLACEHOLDER_ICON_SIZE = 30.0; // Increased from 24

// Contact Info Text Size
const double _CONTACT_HEADER_SIZE = 20.0; // Increased from 18
const double _CONTACT_INFO_SIZE = 18.0; // Increased from 16
const double _LAST_UPDATED_SIZE = 16.0; // Increased from 14
// =============================================

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isCompact;

  const ProductCard({
    super.key, 
    required this.product,
    this.onTap,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Card(
          elevation: _isHovered ? 8 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: _isHovered ? Colors.blue.shade50 : Colors.white,
          child: widget.isCompact ? _buildCompactLayout(context) : _buildNormalLayout(context),
        ),
      ),
    );
  }

  Widget _buildNormalLayout(BuildContext context) {
    return Row( // CHANGED: From Column to Row
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ADDED: Action buttons on the left
        Container(
          width: 80, // Fixed width for buttons column
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Edit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(0, 55),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: _NORMAL_ICON_SIZE),
                      const SizedBox(height: 2),
                      Text(
                        'ערוך',
                        style: TextStyle(fontSize: _NORMAL_BUTTON_TEXT_SIZE - 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Delete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 40),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete, size: _NORMAL_ICON_SIZE),
                      const SizedBox(height: 2),
                      Text(
                        'מחק',
                        style: TextStyle(fontSize: _NORMAL_BUTTON_TEXT_SIZE - 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main product content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildProductImage(),
              ),
              Expanded(
                flex: 2,
                child: _buildProductInfoWithoutButtons(context), // CHANGED: New method without spacer
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ADDED: Action buttons on the left (more compact)
        Container(
          width: 60, // Smaller width for compact layout
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Edit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 50),
                  ),
                  child: Icon(Icons.edit, size: _COMPACT_ICON_SIZE),
                ),
              ),
              const SizedBox(height: 10),
              // Delete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 50),
                  ),
                  child: Icon(Icons.delete, size: _COMPACT_ICON_SIZE),
                ),
              ),
            ],
          ),
        ),
        // Content in the middle
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Product name
                Text(
                  widget.product.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isHovered ? Colors.blue[700] : null,
                    fontSize: _COMPACT_TITLE_SIZE,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: _COMPACT_DESCRIPTION_SIZE,
                    ),
                    textDirection: TextDirection.rtl,
                    // REMOVED: maxLines constraint to allow full description
                  ),
                // Main SKU (if available)
                if (widget.product.productSku != null && widget.product.productSku!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'מק״ט ראשי: ${widget.product.productSku}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: _COMPACT_SKU_SIZE,
                    ),
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Add variants display
                _buildVariantsDisplay(),

                // REMOVED: Action buttons from here
              ],
            ),
          ),
        ),
        // Image on the right
        Container(
          width: 140,
          margin: const EdgeInsets.all(8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 140,
                maxHeight: 180,
                minWidth: 140,
                minHeight: 120,
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _buildProductImage(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsDisplay() {
    // Debug print to check if variants exist
    print('Product ${widget.product.productName} has ${widget.product.variants.length} variants');
    if (widget.product.variants.isNotEmpty) {
      print('Variants: ${widget.product.variants.map((v) => '${v.color}:${v.sku}').join(', ')}');
    }
    
    if (!widget.product.hasVariants) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 6),
        // Table Container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: widget.isCompact ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl, // RTL for the row
                  children: [
                    // SKU Column Header (now first - rightmost)
                    Expanded(
                      flex: 2,
                      child: Text(
                        'מק״ט',
                        style: TextStyle(
                          fontSize: widget.isCompact ? 13 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: widget.isCompact ? 12 : 14,
                      color: Colors.blue[300],
                    ),
                    // Color Column Header (now second - leftmost)
                    Expanded(
                      flex: 3,
                      child: Text(
                        'תיאור',
                        style: TextStyle(
                          fontSize: widget.isCompact ? 13 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
              // Table Rows
              ...widget.product.variants.asMap().entries.map((entry) {
                final index = entry.key;
                final variant = entry.value;
                final isLastRow = index == widget.product.variants.length - 1;
                
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: widget.isCompact ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Colors.blue[25],
                    borderRadius: isLastRow ? const BorderRadius.only(
                      bottomLeft: Radius.circular(7),
                      bottomRight: Radius.circular(7),
                    ) : null,
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl, // RTL for the row
                    children: [
                      // SKU Column (now first - rightmost)
                      Expanded(
                        flex: 2,
                        child: Text(
                          variant.sku.isNotEmpty ? variant.sku : 'ללא מק״ט',
                          style: TextStyle(
                            fontSize: widget.isCompact ? 12 : 13,
                            color: variant.sku.isNotEmpty 
                                ? Colors.blue[700] 
                                : Colors.grey[500],
                            fontWeight: variant.sku.isNotEmpty 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                            fontStyle: variant.sku.isEmpty 
                                ? FontStyle.italic 
                                : FontStyle.normal,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Divider
                      Container(
                        width: 1,
                        height: widget.isCompact ? 16 : 18,
                        color: Colors.blue[200],
                      ),
                      // Color Column (now second - leftmost)
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: TextDirection.rtl, // RTL for color row content
                          children: [
                            // Color name (first in RTL)
                            Flexible(
                              child: Text(
                                variant.color,
                                style: TextStyle(
                                  fontSize: widget.isCompact ? 12 : 13,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Color dot (after text in RTL)
                            if (variant.colorHex != null && variant.colorHex!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: widget.isCompact ? 12 : 14,
                                height: widget.isCompact ? 12 : 14,
                                decoration: BoxDecoration(
                                  color: _parseColorHex(variant.colorHex!),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: Colors.grey[400]!, 
                                    width: 0.5,
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
              }).toList(),
              // Additional notes footer (if any variant has notes)
              if (widget.product.variants.any((v) => 
                  v.additionalNotes != null && v.additionalNotes!.isNotEmpty))
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: widget.isCompact ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(7),
                      bottomRight: Radius.circular(7),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.orange[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl, // RTL for notes row
                    children: [
                      Expanded(
                        child: Text(
                          'הערות נוספות זמינות',
                          style: TextStyle(
                            fontSize: widget.isCompact ? 8 : 9,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: widget.isCompact ? 12 : 14,
                        color: Colors.orange[600],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to safely parse color hex
  Color _parseColorHex(String hexColor) {
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex'; // Add alpha if missing
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      print('Error parsing color hex: $hexColor, error: $e');
      return Colors.grey[400]!; // Fallback color
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'אישור מחיקה',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: _NORMAL_TITLE_SIZE),
          ),
          content: Text(
            'האם אתה בטוח שברצונך למחוק את המוצר "${widget.product.productName}"?',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: _NORMAL_DESCRIPTION_SIZE),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ביטול', style: TextStyle(fontSize: _NORMAL_BUTTON_TEXT_SIZE)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete?.call();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('מחק', style: TextStyle(fontSize: _NORMAL_BUTTON_TEXT_SIZE)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductImage() {
    if (widget.product.imagePath.isEmpty) {
      return _buildPlaceholderImage();
    }

    String imageUrl = _getCorsProxiedUrl(widget.product.imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain, // Changed from cover to contain - shows full image
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error, URL: $imageUrl');
          if (imageUrl != widget.product.imagePath) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.product.imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain, // Changed here too
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorImage();
                },
              ),
            );
          }
          return _buildErrorImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingImage(loadingProgress);
        },
      ),
    );
  }

  String _getCorsProxiedUrl(String originalUrl) {
    final corsProblematicDomains = [
      'drive.google.com',
      'googleusercontent.com', 
      'docs.google.com',
    ];
    
    bool needsProxy = corsProblematicDomains.any((domain) => originalUrl.contains(domain));
    
    if (needsProxy) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    
    return originalUrl;
  }

  Widget _buildErrorImage() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.red[400],
            size: widget.isCompact ? _COMPACT_ERROR_ICON_SIZE : _NORMAL_ERROR_ICON_SIZE,
          ),
          const SizedBox(height: 4),
          Text(
            'שגיאה בטעינת תמונה',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: widget.isCompact ? _COMPACT_ERROR_TEXT_SIZE : _NORMAL_ERROR_TEXT_SIZE,
            ),
            textAlign: TextAlign.center,
          ),
          if (!widget.isCompact) ...[
            const SizedBox(height: 2),
            Text(
              'CORS/Network Error',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: widget.isCompact ? _COMPACT_ERROR_TEXT_SIZE - 2 : _NORMAL_ERROR_TEXT_SIZE - 2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingImage(ImageChunkEvent loadingProgress) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: widget.isCompact ? 24 : 28,
            height: widget.isCompact ? 24 : 28,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'טוען תמונה...',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: widget.isCompact ? _COMPACT_LOADING_TEXT_SIZE : _NORMAL_LOADING_TEXT_SIZE,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: Colors.grey[400],
            size: widget.isCompact ? _COMPACT_PLACEHOLDER_ICON_SIZE : _NORMAL_PLACEHOLDER_ICON_SIZE,
          ),
          const SizedBox(height: 4),
          Text(
            'אין תמונה',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: widget.isCompact ? _COMPACT_PLACEHOLDER_TEXT_SIZE : _NORMAL_PLACEHOLDER_TEXT_SIZE,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.product.productName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isHovered ? Colors.blue[700] : null,
              fontSize: _NORMAL_TITLE_SIZE,
            ),
            maxLines: 100,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: _NORMAL_DESCRIPTION_SIZE,
            ),
            maxLines: 100,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
          // SKU (if available) - Added under description
          if (widget.product.productSku != null && widget.product.productSku!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'מק״ט ראשי: ${widget.product.productSku}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: _NORMAL_SKU_SIZE,
              ),
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Add variants display
          _buildVariantsDisplay(),
        ],
      ),
    );
  }

  // ADDED: New method for product info without action buttons
  Widget _buildProductInfoWithoutButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.product.productName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isHovered ? Colors.blue[700] : null,
              fontSize: _NORMAL_TITLE_SIZE,
            ),
            maxLines: 2, // CHANGED: Limit to 2 lines to save space
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),
          Expanded( // CHANGED: Use Expanded to fill available space
            child: Text(
              widget.product.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: _NORMAL_DESCRIPTION_SIZE,
              ),
              textDirection: TextDirection.rtl,
              // REMOVED: maxLines constraint to show full description
            ),
          ),
          // SKU (if available)
          if (widget.product.productSku != null && widget.product.productSku!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'מק״ט ראשי: ${widget.product.productSku}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: _NORMAL_SKU_SIZE,
              ),
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Add variants display
          _buildVariantsDisplay(),
        ],
      ),
    );
  }
}