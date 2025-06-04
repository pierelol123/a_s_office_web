import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/model/ImageUtils.dart';
import 'package:a_s_office_web/services/GoogleDriveService.dart';
import 'dart:io'; // Make sure this import is present

class ProductEditPage extends StatefulWidget {
  final Product product;
  final Function(Product) onSave;
  final bool isNewProduct;

  const ProductEditPage({
    super.key,
    required this.product,
    required this.onSave,
    this.isNewProduct = false,
  });

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  late TextEditingController _imagePathController;
  late TextEditingController _descriptionController;
  late TextEditingController _pageNumberController; // New controller
  late TextEditingController _rowInPageController; // New controller
  late TextEditingController _heightController; // New controller
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.productName);
    _priceController = TextEditingController(text: widget.product.productPrice.toString());
    _capacityController = TextEditingController(text: widget.product.productCapacity.toString());
    _imagePathController = TextEditingController(text: widget.product.imagePath);
    _descriptionController = TextEditingController(text: widget.product.description);
    _pageNumberController = TextEditingController(text: widget.product.pageNumber.toString());
    _rowInPageController = TextEditingController(text: widget.product.rowInPage.toString());
    _heightController = TextEditingController(text: widget.product.height.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _imagePathController.dispose();
    _descriptionController.dispose();
    _pageNumberController.dispose();
    _rowInPageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNewProduct ? 'הוסף מוצר חדש' : 'ערוך מוצר',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[600],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                labelText: 'שם המוצר',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'אנא הזן שם מוצר';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                labelText: 'תיאור',
                maxLines: 100, // Allow unlimited lines
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      labelText: 'מחיר',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'אנא הזן מספר תקין';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _capacityController,
                      labelText: 'קיבולת',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'אנא הזן מספר שלם';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _pageNumberController,
                      labelText: 'מספר עמוד',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'אנא הזן מספר עמוד';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'אנא הזן מספר עמוד תקין (1 ומעלה)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _rowInPageController,
                      labelText: 'מספר שורה בעמוד',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'אנא הזן מספר שורה';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'אנא הזן מספר שורה תקין (1 ומעלה)';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _heightController,
                labelText: 'גובה המוצר (בפיקסלים)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'אנא הזן גובה למוצר';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height < 50 || height > 500) {
                    return 'אנא הזן גובה תקין (בין 50 ל-500 פיקסלים)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _imagePathController,
                labelText: 'נתיב תמונה',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.isNewProduct ? 'הוסף מוצר' : 'שמור שינויים',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        alignLabelWithHint: maxLines > 1, // Align label with hint for multiline
      ),
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType, // Use multiline for multi-line fields
      maxLines: maxLines,
      minLines: maxLines > 1 ? 1 : null, // Allow field to start small and grow
      textDirection: TextDirection.rtl,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next, // Allow new line action
      validator: validator,
    );
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProduct = Product(
        productID:
            widget.isNewProduct
                ? DateTime.now()
                    .millisecondsSinceEpoch // Generate new ID for new products
                : widget.product.productID, // Keep existing ID for edits
        productName: _nameController.text,
        productPrice: double.tryParse(_priceController.text) ?? 0.0,
        productCapacity: int.tryParse(_capacityController.text) ?? 0,
        imagePath: _imagePathController.text,
        dateAdded:
            widget.isNewProduct
                ? DateTime.now()
                    .toIso8601String() // New date for new products
                : widget.product.dateAdded, // Keep existing date for edits
        description: _descriptionController.text,
        totalQuantitySold:
            widget.isNewProduct ? 0 : widget.product.totalQuantitySold,
        buyers: widget.isNewProduct ? [] : widget.product.buyers,
        pageNumber: int.tryParse(_pageNumberController.text) ?? 1, // New field
        rowInPage: int.tryParse(_rowInPageController.text) ?? 1, // New field
        height: double.tryParse(_heightController.text) ?? 160.0, // New field
      );

      widget.onSave(updatedProduct);
      Navigator.of(context).pop();
    }
  }
}
