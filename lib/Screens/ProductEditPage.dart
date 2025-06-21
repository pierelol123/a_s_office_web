import 'dart:typed_data';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/model/ImageUtils.dart';
import 'package:a_s_office_web/services/GoogleDriveService.dart';

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
  // ============================================
  // ADJUSTABLE SIZING PARAMETERS - MODIFY THESE
  // ============================================
  
  // Text field sizing
  static const double textFieldHeight = 70.0;        // Default: 56.0 - Height of text fields
  static const double textFieldFontSize = 20.0;      // Default: 16.0 - Font size inside text fields
  static const double labelFontSize = 20.0;          // Default: 14.0 - Label text size
  static const double textFieldPadding = 20.0;       // Default: 16.0 - Internal padding of text fields
  
  // Multiline text field sizing
  static const double multilineMinHeight = 120.0;    // Default: 56.0 - Minimum height for description field
  static const int multilineMaxLines = 6;            // Default: 100 - Max lines for description
  
  // Button sizing
  static const double buttonHeight = 60.0;           // Default: 48.0 - Height of buttons
  static const double buttonFontSize = 18.0;         // Default: 16.0 - Font size in buttons
  
  // Spacing between elements
  static const double elementSpacing = 24.0;         // Default: 16.0 - Space between form elements
  static const double sectionSpacing = 40.0;         // Default: 32.0 - Space before save button
  
  // Form padding
  static const double formPadding = 24.0;            // Default: 16.0 - Overall form padding
  
  // ============================================
  // AUTO HEIGHT CALCULATION PARAMETERS
  // ============================================
  
  static const double baseHeight = 160.0;            // Base height for products
  static const double heightPerDescriptionLine = 20.0; // Height per line of description
  static const double heightPerVariant = 20;        // Height per variant
  static const double maxCalculatedHeight = 500.0;   // Maximum auto-calculated height
  static const double minCalculatedHeight = 120.0;   // Minimum auto-calculated height
  static const int charactersPerLine = 45;           // Approximate characters per line in description
  
  // ============================================
  // END OF ADJUSTABLE PARAMETERS
  // ============================================

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _productSkuController;
  late TextEditingController _imagePathController;
  late TextEditingController _descriptionController;
  late TextEditingController _pageNumberController;
  late TextEditingController _rowInPageController;
  late TextEditingController _heightController;
  bool _isUploading = false;

  List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.productName);
    _priceController = TextEditingController(text: widget.product.productPrice.toString());
    _productSkuController = TextEditingController(text: widget.product.productSku ?? ''); 
    _imagePathController = TextEditingController(text: widget.product.imagePath);
    _descriptionController = TextEditingController(text: widget.product.description);
    _pageNumberController = TextEditingController(text: widget.product.pageNumber.toString());
    _rowInPageController = TextEditingController(text: widget.product.rowInPage.toString());
    _heightController = TextEditingController(text: widget.product.height.toString());
    _variants = List.from(widget.product.variants);
    
    // Add listeners to automatically update height
    _descriptionController.addListener(_updateHeightBasedOnContent);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _productSkuController.dispose();
    _imagePathController.dispose();
    _descriptionController.dispose();
    _pageNumberController.dispose();
    _rowInPageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ============================================
  // AUTO HEIGHT CALCULATION LOGIC
  // ============================================
  
  void _updateHeightBasedOnContent() {
    final newHeight = _calculateOptimalHeight();
    setState(() {
      _heightController.text = newHeight.toStringAsFixed(0);
    });
  }

  double _calculateOptimalHeight() {
    double calculatedHeight = baseHeight;
    
    // Add height for description
    final descriptionText = _descriptionController.text;
    if (descriptionText.isNotEmpty) {
      // Count actual line breaks first
      final explicitLines = descriptionText.split('\n').length;
      
      // Calculate approximate lines based on character count for word wrapping
      int approximateLines = 0;
      for (String line in descriptionText.split('\n')) {
      if (line.isEmpty) {
        approximateLines += 1;
      } else {
        approximateLines += (line.length / charactersPerLine).ceil();
      }
      }
      
      // Use the maximum of explicit lines and calculated wrapped lines
      final actualLines = (explicitLines > approximateLines ? explicitLines : approximateLines).clamp(1, 20);
      
      // Add extra height for description lines beyond the first line
      if (actualLines > 1) {
      calculatedHeight += (actualLines - 1) * heightPerDescriptionLine;
      }
    }
    
    // Add height for variants - IMPROVED CALCULATION
    if (_variants.isNotEmpty) {
      // Base variants section height (header + container padding)
      calculatedHeight += heightPerVariant; // Increased from 30.0
      
      // Add height per variant (more accurate calculation)
      final variantHeight = _variants.length * heightPerVariant;
      calculatedHeight += variantHeight;
      
      // Additional padding for variants table
      calculatedHeight += 20.0; // Extra padding for table structure
    }
    
    // Ensure height is within reasonable bounds
    return calculatedHeight.clamp(minCalculatedHeight, maxCalculatedHeight);
  }

  // ============================================
  // VARIANTS SECTION WITH AUTO HEIGHT UPDATE
  // ============================================

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _addVariant,
              icon: const Icon(Icons.add),
              label: const Text('הוסף מגוון'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
            Row(
              children: [
                // Auto-calculate height button
                IconButton(
                  onPressed: () {
                    _updateHeightBasedOnContent();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('גובה המוצר עודכן אוטומטית'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'חישוב גובה אוטומטי',
                  color: Colors.blue[600],
                ),
                Text(
                  'גוונים וצבעים (${_variants.length})',
                  style: TextStyle(
                    fontSize: labelFontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_variants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              'אין גוונים מוגדרים למוצר זה',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: textFieldFontSize - 2,
              ),
            ),
          )
        else
          ...List.generate(_variants.length, (index) => 
            _buildVariantCard(index)
          ),
      ],
    );
  }

  Widget _buildVariantCard(int index) {
    final variant = _variants[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Delete button
              IconButton(
                onPressed: () => _removeVariant(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'מחק גוון',
              ),
              const SizedBox(width: 8),
              // Color preview
              if (variant.colorHex != null)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(int.parse(variant.colorHex!.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                ),
              const SizedBox(width: 16),
              // Variant number
              Text(
                'גוון ${index + 1}',
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: variant.sku,
                  decoration: InputDecoration(
                    labelText: 'מק״ט',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontSize: textFieldFontSize - 2),
                  textDirection: TextDirection.rtl,
                  onChanged: (value) {
                    setState(() {
                      _variants[index] = ProductVariant(
                        color: variant.color,
                        sku: value,
                        colorHex: variant.colorHex,
                        additionalNotes: variant.additionalNotes,
                      );
                      // Auto-update height when variants change
                      _updateHeightBasedOnContent();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: variant.color,
                  decoration: InputDecoration(
                    labelText: 'תיאור',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontSize: textFieldFontSize - 2),
                  textDirection: TextDirection.rtl,
                  onChanged: (value) {
                    setState(() {
                      _variants[index] = ProductVariant(
                        color: value,
                        sku: variant.sku,
                        colorHex: variant.colorHex,
                        additionalNotes: variant.additionalNotes,
                      );
                      // Auto-update height when variants change
                      _updateHeightBasedOnContent();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: variant.colorHex,
                  decoration: InputDecoration(
                    labelText: 'צבע',
                    hintText: '#FF0000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontSize: textFieldFontSize - 3),
                  onChanged: (value) {
                    setState(() {
                      _variants[index] = ProductVariant(
                        color: variant.color,
                        sku: variant.sku,
                        colorHex: value.isEmpty ? null : value,
                        additionalNotes: variant.additionalNotes,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addVariant() {
    setState(() {
      _variants.add(ProductVariant(
        color: '',
        sku: '',
        colorHex: null,
        additionalNotes: null,
      ));
      // Auto-update height when adding variants
      _updateHeightBasedOnContent();
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
      // Auto-update height when removing variants
      _updateHeightBasedOnContent();
    });
  }

  // ============================================
  // ENHANCED HEIGHT FIELD WITH AUTO CALCULATION
  // ============================================

  Widget _buildHeightField() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
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
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            // Auto-calculate button
            ElevatedButton.icon(
              onPressed: () {
                _updateHeightBasedOnContent();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('גובה המוצר חושב אוטומטית'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('חישוב אוטומטי'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 4),
            // Show calculated height
            Text(
              'מומלץ: ${_calculateOptimalHeight().toStringAsFixed(0)}px',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _uploadImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Use file_selector for Windows desktop
      const XTypeGroup imageTypeGroup = XTypeGroup(
        label: 'images',
        extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[imageTypeGroup],
      );

      if (file != null) {
        print('Selected file: ${file.name}');
        print('File path: ${file.path}');

        // Show uploading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    Text(
                      'מעלה תמונה ל-Google Drive...',
                      style: TextStyle(fontSize: textFieldFontSize),
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Read file bytes using dart:io
        final File ioFile = File(file.path);
        final Uint8List fileBytes = await ioFile.readAsBytes();
        
        print('File size: ${fileBytes.length} bytes');

        // Upload to Google Drive
        final imageUrl = await GoogleDriveService.uploadImageToDrive(
          imageBytes: fileBytes,
          fileName: file.name,
        );

        // Close uploading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (imageUrl != null) {
          setState(() {
            _imagePathController.text = imageUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'התמונה הועלתה בהצלחה!',
                  style: TextStyle(fontSize: textFieldFontSize),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to get image URL from Google Drive');
        }
      } else {
        print('No file selected');
      }
    } catch (e, stackTrace) {
      print('Error uploading image: $e');
      print('Stack trace: $stackTrace');
      
      // Close uploading dialog if it's open
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'שגיאה בהעלאת התמונה: $e',
              style: TextStyle(fontSize: textFieldFontSize),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNewProduct ? 'הוסף מוצר חדש' : 'ערוך מוצר',
          style: TextStyle(
            color: Colors.white,
            fontSize: buttonFontSize + 2,
          ),
        ),
        backgroundColor: Colors.blue[600],
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: buttonHeight + 10,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(formPadding),
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
                SizedBox(height: elementSpacing),
                _buildTextField(
                  controller: _descriptionController,
                  labelText: 'תיאור',
                  maxLines: multilineMaxLines,
                  isMultiline: true,
                ),
                SizedBox(height: elementSpacing),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _productSkuController,
                        labelText: 'מק״ט של המוצר',
                        validator: (value) {
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: elementSpacing),
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
                  ],
                ),
                SizedBox(height: elementSpacing),
                _buildVariantsSection(),
                SizedBox(height: elementSpacing),
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
                    SizedBox(width: elementSpacing),
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
                SizedBox(height: elementSpacing),
                // UPDATED: Enhanced height field with auto-calculation
                _buildHeightField(),
                SizedBox(height: elementSpacing),
                // Image section with upload button
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: _imagePathController,
                        labelText: 'נתיב תמונה',
                      ),
                    ),
                    SizedBox(width: elementSpacing),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: textFieldHeight,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadImage,
                          icon: _isUploading 
                            ? SizedBox(
                                width: buttonFontSize,
                                height: buttonFontSize,
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.upload, size: buttonFontSize + 2),
                          label: Text(
                            _isUploading ? 'מעלה...' : 'העלה תמונה',
                            style: TextStyle(fontSize: buttonFontSize - 2),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Image preview if URL exists
                if (_imagePathController.text.isNotEmpty) ...[
                  SizedBox(height: elementSpacing),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imagePathController.text,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: buttonFontSize + 4),
                                Text(
                                  'שגיאה בטעינת התמונה',
                                  style: TextStyle(fontSize: textFieldFontSize),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                SizedBox(height: sectionSpacing),
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.isNewProduct ? 'הוסף מוצר' : 'שמור שינויים',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    bool isMultiline = false,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: isMultiline ? null : textFieldHeight,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(
              fontSize: labelFontSize,
              color: Colors.grey[700],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            alignLabelWithHint: isMultiline,
            contentPadding: EdgeInsets.all(textFieldPadding),
            errorStyle: TextStyle(fontSize: labelFontSize - 2),
            floatingLabelAlignment: FloatingLabelAlignment.start,
          ),
          style: TextStyle(
            fontSize: textFieldFontSize,
            color: Colors.black87,
          ),
          keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
          maxLines: isMultiline ? maxLines : 1,
          minLines: isMultiline ? 3 : 1,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          textInputAction: isMultiline ? TextInputAction.newline : TextInputAction.next,
          validator: validator,
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProduct = Product(
        productID:
            widget.isNewProduct
                ? DateTime.now().millisecondsSinceEpoch
                : widget.product.productID,
        productName: _nameController.text,
        productPrice: double.tryParse(_priceController.text) ?? 0.0,
        productCapacity: 0,
        productSku: _productSkuController.text.isEmpty ? null : _productSkuController.text,
        variants: _variants,
        imagePath: _imagePathController.text,
        dateAdded:
            widget.isNewProduct
                ? DateTime.now().toIso8601String()
                : widget.product.dateAdded,
        description: _descriptionController.text,
        totalQuantitySold:
            widget.isNewProduct ? 0 : widget.product.totalQuantitySold,
        buyers: widget.isNewProduct ? [] : widget.product.buyers,
        pageNumber: int.tryParse(_pageNumberController.text) ?? 1,
        rowInPage: int.tryParse(_rowInPageController.text) ?? 1,
        height: double.tryParse(_heightController.text) ?? 170.0,
      );

      widget.onSave(updatedProduct);
      Navigator.of(context).pop();
    }
  }
}