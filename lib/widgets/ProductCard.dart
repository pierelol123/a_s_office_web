import 'package:flutter/material.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/model/ImageUtils.dart';

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
                    fontSize: 14,
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
                    fontSize: 11,
                  ),
                  maxLines: 100,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                const Spacer(),
                // Price and ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'מק"ט: ${widget.product.productID}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 10,
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
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('ערוך', style: TextStyle(fontSize: 11)),
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
                        icon: const Icon(Icons.delete, size: 14),
                        label: const Text('מחק', style: TextStyle(fontSize: 11)),
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
              maxHeight: 120,
              minWidth: 120,
              minHeight: 120,
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
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('ערוך'),
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
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('מחק'),
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
          title: const Text(
            'אישור מחיקה',
            textDirection: TextDirection.rtl,
          ),
          content: Text(
            'האם אתה בטוח שברצונך למחוק את המוצר "${widget.product.productName}"?',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete?.call();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('מחק'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductImage() {
    final imageUrl = ImageUtils.convertGoogleDriveUrl(widget.product.imagePath);
    
    return Container(
      width: widget.isCompact ? 120 : null, // Force width for compact mode
      height: widget.isCompact ? 120 : null, // Force height for compact mode
      decoration: BoxDecoration(
        borderRadius: widget.isCompact 
            ? const BorderRadius.horizontal(right: Radius.circular(16))
            : const BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.grey[200],
      ),
      child: widget.product.imagePath.isNotEmpty && ImageUtils.isValidImageUrl(widget.product.imagePath)
          ? ClipRRect(
              borderRadius: widget.isCompact 
                  ? const BorderRadius.horizontal(right: Radius.circular(16))
                  : const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: widget.isCompact ? 120 : double.infinity,
                height: widget.isCompact ? 120 : double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.blue[600],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return _buildPlaceholderImage();
                },
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.isCompact 
            ? const BorderRadius.horizontal(right: Radius.circular(16)) // Changed to right
            : const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: widget.isCompact ? 32 : 40,
              color: Colors.grey,
            ),
            SizedBox(height: widget.isCompact ? 6 : 8),
            Text(
              'אין תמונה',
              style: TextStyle(
                color: Colors.grey,
                fontSize: widget.isCompact ? 12 : 12,
              ),
            ),
          ],
        ),
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
            ),
            maxLines: 100,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
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
          'מק"ט: ${widget.product.productID}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
          textDirection: TextDirection.rtl,
        ),
        _buildPriceWidget(context),
      ],
    );
  }

  Widget _buildPriceWidget(BuildContext context) {
    if (widget.product.productPrice > 0) {
      return Text(
        '₪${widget.product.productPrice.toStringAsFixed(0)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _isHovered ? Colors.blue[800] : Colors.blue[600],
          fontWeight: FontWeight.bold,
          fontSize: widget.isCompact ? 12 : null, // Smaller font for compact mode
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
          fontSize: widget.isCompact ? 10 : null, // Smaller font for compact mode
        ),
        textDirection: TextDirection.rtl,
        overflow: TextOverflow.ellipsis,
      );
    }
  }
}