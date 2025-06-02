import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  late TextEditingController _imagePathController;
  late TextEditingController _descriptionController;
  bool _isUploading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // For new products, start with empty fields
    _nameController = TextEditingController(
      text: widget.isNewProduct ? '' : widget.product.productName,
    );
    _priceController = TextEditingController(
      text: widget.isNewProduct ? '' : widget.product.productPrice.toString(),
    );
    _capacityController = TextEditingController(
      text:
          widget.isNewProduct ? '' : widget.product.productCapacity.toString(),
    );
    _imagePathController = TextEditingController(
      text: widget.isNewProduct ? '' : widget.product.imagePath,
    );
    _descriptionController = TextEditingController(
      text: widget.isNewProduct ? '' : widget.product.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _imagePathController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNewProduct ? 'הוסף מוצר חדש' : 'עריכת מוצר',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[600],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _saveProduct,
            child: Text(
              widget.isNewProduct ? 'הוסף' : 'שמור',
              style: TextStyle(
                color: _isUploading ? Colors.grey : Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'שם המוצר',
                validator:
                    (value) => value?.isEmpty ?? true ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'תיאור',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'מחיר',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    if (double.tryParse(value!) == null) {
                      return 'הכנס מספר תקין';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _capacityController,
                label: 'קיבולת',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    if (int.tryParse(value!) == null) {
                      return 'הכנס מספר שלם תקין';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildImageSection(),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isUploading ? Colors.grey : Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isUploading
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('מעלה תמונה...'),
                            ],
                          )
                          : Text(
                            widget.isNewProduct ? 'הוסף מוצר' : 'שמור שינויים',
                            style: const TextStyle(fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _imagePathController,
                label: 'נתיב תמונה',
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    if (!ImageUtils.isValidImageUrl(value!)) {
                      return 'הכנס קישור תמונה תקין';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon:
                  _isUploading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Icon(Icons.upload_file),
              label: const Text('העלה תמונה'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'העלה תמונה ישירות או הדבק קישור Google Drive',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textDirection: TextDirection.rtl,
        ),
        if (_imagePathController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ImageUtils.convertGoogleDriveUrl(_imagePathController.text),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey),
                        Text(
                          'תמונה לא נמצאה',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickAndUploadImage() async {
    print('Picking and uploading image...');
    // No need to set _isUploading here if _pasteImageFromClipboard is not used or handles its own state
    // Let's assume _isUploading is primarily for the overall page state during network ops.
    // If _pickAndUploadImage is the only uploader, then it's fine here.
    // For clarity with the paste function, let's manage _isUploading within this function scope
    // if it's not already true from another operation.

    bool wasAlreadyUploading = _isUploading;
    if (!wasAlreadyUploading) {
      setState(() {
        _isUploading = true;
      });
    }
    // If using _isPasting, ensure it's false here
    // _isPasting = false; // Assuming _isPasting is a class member

    try {
      print('Opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // <--- CRUCIAL CHANGE: Request file bytes
      );
      print('File picker result: $result');

      Uint8List? imageBytes;
      String? pickedFileName;

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        pickedFileName = file.name;

        if (file.bytes != null) {
          print('Picked file: ${file.name}, size: ${file.bytes?.length} bytes (from file.bytes)');
          imageBytes = file.bytes;
        } else if (file.path != null) {
          // Fallback: Read bytes from path if file.bytes is null
          print('Picked file: ${file.name}, (file.bytes was null, reading from path: ${file.path})');
          imageBytes = await File(file.path!).readAsBytes();
          print('Bytes read from path: ${imageBytes.length}');
        }
      }

      if (imageBytes != null && pickedFileName != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$pickedFileName';
        print('Generated fileName: $fileName');

        print('Uploading to Google Drive...');
        final driveUrl = await GoogleDriveService.uploadImageToDrive(
          imageBytes: imageBytes,
          fileName: fileName,
          // folderId: 'your-folder-id', // Optional: specify a folder
        );
        print('Google Drive upload result: $driveUrl');

        if (driveUrl != null) {
          setState(() {
            _imagePathController.text = driveUrl;
            print('Set _imagePathController.text to driveUrl');
          });
          _showSuccessSnackBar('התמונה הועלתה בהצלחה');
        } else {
          _showErrorSnackBar('שגיאה בהעלאת התמונה (לא התקבל URL)');
        }
      } else {
        print('No file selected, or failed to read file bytes.');
        // Optionally show a message to the user if no file was picked or read
        // _showInfoSnackBar('לא נבחר קובץ או שלא ניתן היה לקרוא אותו.');
      }
    } catch (e, s) {
      print('Error picking/uploading image: $e');
      print(s); // Print stack trace for more details
      _showErrorSnackBar('שגיאה בבחירת או העלאת תמונה: $e');
    } finally {
      if (!wasAlreadyUploading) { // Only reset if this function set it
        if (mounted) { // Check if widget is still in the tree
          setState(() {
            _isUploading = false;
          });
        }
      }
      print('Image picking/uploading process finished');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl), backgroundColor: Colors.red),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
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
      );

      widget.onSave(updatedProduct);
      Navigator.of(context).pop();
    }
  }
}
