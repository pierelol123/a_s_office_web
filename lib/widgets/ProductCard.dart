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
const double _NORMAL_ICON_SIZE = 20.0; // Increased from 16
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
  final bool isCompact; // New parameter to control layout

  const ProductCard({
    super.key, 
    required this.product,
    this.onTap,
    this.onDelete,
    this.isCompact = false, // Default to false for backward compatibility
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
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0), // Reduced scale for compact mode
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildProductImage(),
        ),
        Expanded(
          flex: 2,
          child: _buildProductInfo(context),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Content on the left
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
                  maxLines: 100,
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
                  maxLines: 100,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                // SKU (if available)
                if (widget.product.productSku != null && widget.product.productSku!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'מק״ט: ${widget.product.productSku}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: _COMPACT_SKU_SIZE,
                    ),
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                // Price and ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'ID: ${widget.product.productID}', // Changed back to ID
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: _COMPACT_ID_SIZE,
                        ),
                        textDirection: TextDirection.rtl,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: _buildPriceWidget(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons (more compact)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onTap,
                        icon: Icon(Icons.edit, size: _COMPACT_ICON_SIZE),
                        label: Text('ערוך', style: TextStyle(fontSize: _COMPACT_BUTTON_TEXT_SIZE)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: Icon(Icons.delete, size: _COMPACT_ICON_SIZE),
                        label: Text('מחק', style: TextStyle(fontSize: _COMPACT_BUTTON_TEXT_SIZE)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Image on the right (fixed size with constraints)
        Align(
          alignment: Alignment.center, // Center the image vertically
          child: Container(
            width: 120,
            height: 120, // Fixed dimensions
            margin: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              maxWidth: 120,
              maxHeight: double.infinity,
              minWidth: 120,
              minHeight: double.infinity,
            ), // Force exact dimensions
            child: _buildProductImage(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onTap,
              icon: Icon(Icons.edit, size: _NORMAL_ICON_SIZE),
              label: Text('ערוך', style: TextStyle(fontSize: _NORMAL_BUTTON_TEXT_SIZE)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showDeleteConfirmation(context),
              icon: Icon(Icons.delete, size: _NORMAL_ICON_SIZE),
              label: Text('מחק', style: TextStyle(fontSize: _NORMAL_BUTTON_TEXT_SIZE)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
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

    // Use CORS proxy for all external images
    String imageUrl = _getCorsProxiedUrl(widget.product.imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error, URL: $imageUrl');
          // If proxy fails, try the original URL
          if (imageUrl != widget.product.imagePath) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.product.imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
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

  // Add this helper method to your ProductCard class
  String _getCorsProxiedUrl(String originalUrl) {
    // List of domains that typically have CORS issues
    final corsProblematicDomains = [
      'drive.google.com',
      'googleusercontent.com', 
      'docs.google.com',
    ];
    
    // Check if the URL contains any problematic domains
    bool needsProxy = corsProblematicDomains.any((domain) => originalUrl.contains(domain));
    
    if (needsProxy) {
      // Use AllOrigins CORS proxy
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
              'מק״ט: ${widget.product.productSku}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: _NORMAL_SKU_SIZE,
              ),
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          _buildProductFooter(context),
        ],
      ),
    );
  }

  Widget _buildProductFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ID: ${widget.product.productID}', // Changed back to ID
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
            fontSize: _NORMAL_ID_SIZE,
          ),
          textDirection: TextDirection.rtl,
        ),
        _buildPriceWidget(context),
      ],
    );
  }

  Widget _buildPriceWidget(BuildContext context) {
    final fontSize = widget.isCompact ? _COMPACT_PRICE_SIZE : _NORMAL_PRICE_SIZE;
    
    if (widget.product.productPrice > 0) {
      return Text(
        '₪${widget.product.productPrice.toStringAsFixed(0)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _isHovered ? Colors.blue[800] : Colors.blue[600],
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
        textDirection: TextDirection.rtl,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        'מחיר לפי פנייה',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _isHovered ? Colors.orange[800] : Colors.orange[600],
          fontWeight: FontWeight.w500,
          fontSize: fontSize - 2, // Slightly smaller for this text
        ),
        textDirection: TextDirection.rtl,
        overflow: TextOverflow.ellipsis,
      );
    }
  }
}