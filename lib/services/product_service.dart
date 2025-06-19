import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:a_s_office_web/model/Product.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProductService {
  static const String _dataFileName = 'products_data.json';
  static const String _historyFolderName = 'history';
  static const int _maxHistoryFiles = 50; // Keep last 50 backup files
  
  // Get the correct file path for saving data
  static Future<String> _getDataFilePath() async {
    try {
      if (kIsWeb) {
        // For web, we can't save to local files easily
        throw Exception('מדפסים שיטתי: אין תמיכה בשמירת קבצים');
      }
      
      // For desktop/mobile, use documents directory
      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory('${directory.path}/ASOfficeWeb');
      
      // Create app directory if it doesn't exist
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
        print('Created app directory: ${appDir.path}');
      }
      
      final filePath = '${appDir.path}/$_dataFileName';
      print('Data file path: $filePath');
      return filePath;
    } catch (e) {
      print('Error getting data file path: $e');
      rethrow;
    }
  }

  // Get the history directory path
  static Future<String> _getHistoryDirectoryPath() async {
    try {
      if (kIsWeb) {
        throw Exception('Web platform does not support file history');
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory('${directory.path}/ASOfficeWeb');
      final historyDir = Directory('${appDir.path}/$_historyFolderName');
      
      // Create history directory if it doesn't exist
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
        print('Created history directory: ${historyDir.path}');
      }
      
      return historyDir.path;
    } catch (e) {
      print('Error getting history directory path: $e');
      rethrow;
    }
  }

  // Create a backup file in the history folder
  static Future<void> _createBackup(List<Product> products, String reason) async {
    try {
      if (kIsWeb) {
        print('Web platform - skipping backup creation');
        return;
      }

      final historyDirPath = await _getHistoryDirectoryPath();
      final timestamp = DateTime.now();
      final formattedTimestamp = '${timestamp.year}'
          '${timestamp.month.toString().padLeft(2, '0')}'
          '${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}'
          '${timestamp.minute.toString().padLeft(2, '0')}'
          '${timestamp.second.toString().padLeft(2, '0')}';
      
      // Create backup filename with timestamp and reason
      final backupFileName = 'backup_${formattedTimestamp}_${reason.replaceAll(' ', '_')}.json';
      final backupFilePath = '$historyDirPath/$backupFileName';

      final Map<String, dynamic> backupData = {
        'products': products.map((product) => product.toJson()).toList(),
        'metadata': {
          'totalProducts': products.length,
          'backupCreated': timestamp.toIso8601String(),
          'reason': reason,
          'version': '1.0',
        },
      };

      final String jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      final File backupFile = File(backupFilePath);
      await backupFile.writeAsString(jsonString);
      
      print('Created backup: $backupFilePath');
      print('Backup reason: $reason');
      print('Products backed up: ${products.length}');

      // Clean up old backup files
      await _cleanupOldBackups();
      
    } catch (e) {
      print('Error creating backup: $e');
      // Don't throw - backup failure shouldn't prevent main operation
    }
  }

  // Clean up old backup files, keeping only the most recent ones
  static Future<void> _cleanupOldBackups() async {
    try {
      final historyDirPath = await _getHistoryDirectoryPath();
      final historyDir = Directory(historyDirPath);
      
      if (!await historyDir.exists()) {
        return;
      }

      // Get all backup files
      final backupFiles = await historyDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      if (backupFiles.length <= _maxHistoryFiles) {
        return; // No cleanup needed
      }

      // Sort files by modification date (oldest first)
      backupFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Delete oldest files, keeping only the most recent _maxHistoryFiles
      final filesToDelete = backupFiles.take(backupFiles.length - _maxHistoryFiles);
      
      for (final file in filesToDelete) {
        try {
          await file.delete();
          print('Deleted old backup: ${file.path}');
        } catch (e) {
          print('Error deleting backup file ${file.path}: $e');
        }
      }

      print('Cleaned up ${filesToDelete.length} old backup files');
      print('Kept ${_maxHistoryFiles} most recent backups');
      
    } catch (e) {
      print('Error cleaning up old backups: $e');
    }
  }

  // Get list of available backup files
  static Future<List<Map<String, dynamic>>> getBackupHistory() async {
    try {
      if (kIsWeb) {
        return [];
      }

      final historyDirPath = await _getHistoryDirectoryPath();
      final historyDir = Directory(historyDirPath);
      
      if (!await historyDir.exists()) {
        return [];
      }

      final backupFiles = await historyDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      // Sort by modification date (newest first)
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      final backupList = <Map<String, dynamic>>[];
      
      for (final file in backupFiles) {
        try {
          final fileName = file.path.split('/').last.split('\\').last;
          final fileSize = await file.length();
          final lastModified = await file.lastModified();
          
          // Try to read metadata from backup file
          String? reason;
          int? productCount;
          try {
            final content = await file.readAsString();
            final data = json.decode(content) as Map<String, dynamic>;
            reason = data['metadata']?['reason'] as String?;
            productCount = data['metadata']?['totalProducts'] as int?;
          } catch (e) {
            print('Could not read metadata from backup $fileName: $e');
          }

          backupList.add({
            'fileName': fileName,
            'filePath': file.path,
            'fileSize': fileSize,
            'lastModified': lastModified,
            'reason': reason ?? 'Unknown',
            'productCount': productCount ?? 0,
          });
        } catch (e) {
          print('Error processing backup file ${file.path}: $e');
        }
      }

      return backupList;
    } catch (e) {
      print('Error getting backup history: $e');
      return [];
    }
  }

  // Restore from a backup file
  static Future<List<Product>> restoreFromBackup(String backupFilePath) async {
    try {
      print('=== Restoring from Backup ===');
      print('Backup file: $backupFilePath');

      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file does not exist: $backupFilePath');
      }

      final String jsonString = await backupFile.readAsString();
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> productsJson = jsonData['products'] ?? [];
      
      final products = productsJson
          .map((productJson) => Product.fromJson(productJson))
          .where((product) => product.productName.isNotEmpty)
          .toList();
      
      print('Restored ${products.length} products from backup');
      
      // Create a new backup before restoring (for safety)
      await _createBackup(products, 'restored_from_backup');
      
      // Save the restored data as the current data
      await saveProductsToFile(products);
      
      return products;
    } catch (e) {
      print('Error restoring from backup: $e');
      rethrow;
    }
  }

  static Future<List<Product>> loadProducts() async {
    try {
      print('=== Loading Products ===');
      
      // First try to load from external file
      try {
        final filePath = await _getDataFilePath();
        final file = File(filePath);
        
        if (await file.exists()) {
          print('Loading from external file: $filePath');
          final String jsonString = await file.readAsString();
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          
          final List<dynamic> productsJson = jsonData['products'] ?? [];
          
          final products = productsJson
              .map((productJson) => Product.fromJson(productJson))
              .where((product) => product.productName.isNotEmpty)
              .toList();
          
          print('Loaded ${products.length} products from external file');
          return products;
        }
      } catch (e) {
        print('Could not load from external file: $e');
      }
      
      // Fallback to assets if external file doesn't exist
      print('Loading from assets...');
      final String jsonString = await rootBundle.loadString('assets/data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> productsJson = jsonData['products'] ?? [];
      
      final products = productsJson
          .map((productJson) => Product.fromJson(productJson))
          .where((product) => product.productName.isNotEmpty)
          .toList();
      
      print('Loaded ${products.length} products from assets');
      
      // Save to external file for future use (this will also create initial backup)
      await saveProductsToFile(products, skipBackup: false, reason: 'initial_load_from_assets');
      
      return products;
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }

  static List<Product> filterProducts(List<Product> products, String query) {
    if (query.isEmpty) return products;
    
    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      return product.productName.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery) ||
          (product.productSku?.toLowerCase().contains(lowerQuery) ?? false); // Add SKU to search
    }).toList();
  }

  static Future<bool> saveProductsToFile(List<Product> products, {bool skipBackup = false, String reason = 'manual_save'}) async {
    try {
      print('=== Saving Products ===');
      
      if (kIsWeb) {
        print('Web platform - cannot save to local files');
        return false;
      }

      // Create backup before saving (unless explicitly skipped)
      if (!skipBackup) {
        await _createBackup(products, reason);
      }
      
      final filePath = await _getDataFilePath();
      print('Saving to: $filePath');
      
      final Map<String, dynamic> data = {
        'products': products.map((product) => product.toJson()).toList(),
        'metadata': {
          'totalProducts': products.length,
          'lastUpdated': DateTime.now().toIso8601String(),
          'version': '1.0',
        },
      };

      final String jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final File file = File(filePath);
      await file.writeAsString(jsonString);
      
      print('Successfully saved ${products.length} products to: $filePath');
      print('File size: ${await file.length()} bytes');
      
      return true;
    } catch (e) {
      print('Error saving products: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  static Future<bool> updateProduct(List<Product> allProducts, Product updatedProduct) async {
    try {
      print('=== Updating Product ===');
      print('Product ID: ${updatedProduct.productID}');
      print('Product Name: ${updatedProduct.productName}');
      print('Product SKU: ${updatedProduct.productSku}'); // Add SKU to debug log
      
      final index = allProducts.indexWhere((p) => p.productID == updatedProduct.productID);
      if (index != -1) {
        allProducts[index] = updatedProduct;
        final success = await saveProductsToFile(allProducts, reason: 'product_update_${updatedProduct.productID}');
        print('Update result: $success');
        return success;
      } else {
        print('Product not found for update');
        return false;
      }
    } catch (e) {
      print('Error updating product: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  static Future<bool> deleteProduct(List<Product> allProducts, int productID) async {
    try {
      print('=== Deleting Product ===');
      print('Product ID: $productID');
      
      final initialLength = allProducts.length;
      allProducts.removeWhere((product) => product.productID == productID);
      
      if (allProducts.length < initialLength) {
        final success = await saveProductsToFile(allProducts, reason: 'product_delete_$productID');
        print('Delete result: $success');
        return success;
      } else {
        print('Product not found for deletion');
        return false;
      }
    } catch (e) {
      print('Error deleting product: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Add product with backup
  static Future<bool> addProduct(List<Product> allProducts, Product newProduct) async {
    try {
      print('=== Adding Product ===');
      print('Product ID: ${newProduct.productID}');
      print('Product Name: ${newProduct.productName}');
      print('Product SKU: ${newProduct.productSku}');
      
      allProducts.add(newProduct);
      final success = await saveProductsToFile(allProducts, reason: 'product_add_${newProduct.productID}');
      print('Add result: $success');
      return success;
    } catch (e) {
      print('Error adding product: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Add a method to get detailed error information
  static Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final info = <String, dynamic>{};
      
      info['platform'] = kIsWeb ? 'Web' : Platform.operatingSystem;
      info['isWeb'] = kIsWeb;
      
      if (!kIsWeb) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          info['documentsDirectory'] = directory.path;
          info['documentsExists'] = await directory.exists();
          
          final appDir = Directory('${directory.path}/ASOfficeWeb');
          info['appDirectory'] = appDir.path;
          info['appDirectoryExists'] = await appDir.exists();
          
          final filePath = await _getDataFilePath();
          info['dataFilePath'] = filePath;
          
          final file = File(filePath);
          info['dataFileExists'] = await file.exists();
          
          if (await file.exists()) {
            info['dataFileSize'] = await file.length();
            info['dataFileLastModified'] = (await file.lastModified()).toString();
          }

          // History directory info
          try {
            final historyDirPath = await _getHistoryDirectoryPath();
            info['historyDirectory'] = historyDirPath;
            
            final historyDir = Directory(historyDirPath);
            info['historyDirectoryExists'] = await historyDir.exists();
            
            if (await historyDir.exists()) {
              final backupFiles = await historyDir
                  .list()
                  .where((entity) => entity is File && entity.path.endsWith('.json'))
                  .length;
              info['backupFilesCount'] = backupFiles;
            }
          } catch (e) {
            info['historyDirectoryError'] = e.toString();
          }
          
          // Test write permissions
          try {
            final testFile = File('${appDir.path}/test_write.txt');
            await testFile.writeAsString('test');
            await testFile.delete();
            info['canWrite'] = true;
          } catch (e) {
            info['canWrite'] = false;
            info['writeError'] = e.toString();
          }
          
        } catch (e) {
          info['directoryError'] = e.toString();
        }
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}