import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/services/product_service.dart';
import 'package:a_s_office_web/services/pdf/pdf_service.dart';

class CatalogUtils {
  static Future<void> generatePdf(List<Product> allProducts, BuildContext context) async {
    try {
      await PdfService.generateCatalogPdf(allProducts, context);
      print('PDF generated successfully');
    } catch (e) {
      print('Error in generatePdf: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת הקטלוג: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> openFileLocation(BuildContext context) async {
    try {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('פתיחת מיקום קובץ לא זמינה בגרסת הווב'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory('${directory.path}/ASOfficeWeb');
      
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
        print('Created app directory for catalog storage: ${appDir.path}');
      }
      
      final catalogDirectory = appDir.path;
      print('Opening catalog directory: $catalogDirectory');

      if (Platform.isWindows) {
        await Process.run('explorer', [catalogDirectory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [catalogDirectory]);
      } else if (Platform.isLinux) {
        try {
          await Process.run('xdg-open', [catalogDirectory]);
        } catch (e) {
          try {
            await Process.run('nautilus', [catalogDirectory]);
          } catch (e) {
            try {
              await Process.run('dolphin', [catalogDirectory]);
            } catch (e) {
              throw Exception('לא ניתן לפתוח את סייר הקבצים');
            }
          }
        }
      } else {
        throw Exception('פלטפורמה לא נתמכת: ${Platform.operatingSystem}');
      }

      if (context.mounted) {
        final catalogFiles = await _getCatalogFiles(catalogDirectory);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('נפתח סייר קבצים'),
                const SizedBox(height: 4),
                Text(
                  catalogDirectory,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                if (catalogFiles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'נמצאו ${catalogFiles.length} קטלוגים',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: catalogFiles.isNotEmpty ? SnackBarAction(
              label: 'הצג קבצים',
              textColor: Colors.white,
              onPressed: () => _showCatalogFiles(context, catalogFiles),
            ) : null,
          ),
        );
      }
    } catch (e) {
      print('Error opening catalog directory: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בפתיחת תיקיית הקטלוגים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> showFileInfo(BuildContext context) async {
    try {
      final systemInfo = await ProductService.getSystemInfo();
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('מידע על קבצי הנתונים'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoRow('פלטפורמה', systemInfo['platform']?.toString() ?? 'לא ידוע'),
                    _buildInfoRow('תיקיית מסמכים', systemInfo['documentsDirectory']?.toString() ?? 'לא נמצאה'),
                    _buildInfoRow('תיקיית האפליקציה', systemInfo['appDirectory']?.toString() ?? 'לא נמצאה'),
                    _buildInfoRow('קובץ נתונים', systemInfo['dataFilePath']?.toString() ?? 'לא נמצא'),
                    _buildInfoRow('קובץ קיים', systemInfo['dataFileExists'] == true ? 'כן' : 'לא'),
                    if (systemInfo['dataFileSize'] != null)
                      _buildInfoRow('גודל קובץ', '${systemInfo['dataFileSize']} בייטים'),
                    if (systemInfo['dataFileLastModified'] != null)
                      _buildInfoRow('עודכן לאחרונה', systemInfo['dataFileLastModified'].toString()),
                    _buildInfoRow('תיקיית גיבויים', systemInfo['historyDirectory']?.toString() ?? 'לא נמצאה'),
                    _buildInfoRow('גיבויים זמינים', systemInfo['backupFilesCount']?.toString() ?? '0'),
                    _buildInfoRow('הרשאות כתיבה', systemInfo['canWrite'] == true ? 'כן' : 'לא'),
                  ],
                ),
              ),
              actions: [
                if (!kIsWeb) ...[
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openFileLocation(context);
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('פתח תיקייה'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () async {
                    final infoText = systemInfo.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('\n');
                    
                    await Clipboard.setData(ClipboardData(text: infoText));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('מידע הועתק ללוח'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('העתק מידע'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('סגור'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בקבלת מידע על הקובץ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  static Future<List<FileSystemEntity>> _getCatalogFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory.list().toList();
      
      return files.where((file) {
        if (file is File) {
          final fileName = file.path.split(Platform.pathSeparator).last.toLowerCase();
          return fileName.endsWith('.pdf') && 
                 (fileName.contains('catalog') || fileName.contains('קטלוג') || fileName.contains('a_s_office'));
        }
        return false;
      }).toList();
    } catch (e) {
      print('Error getting catalog files: $e');
      return [];
    }
  }

  static void _showCatalogFiles(BuildContext context, List<FileSystemEntity> catalogFiles) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('קטלוגים שמורים'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: catalogFiles.map((file) {
                  final fileName = file.path.split(Platform.pathSeparator).last;
                  final fileStat = file.statSync();
                  final fileSize = (fileStat.size / 1024).toStringAsFixed(1);
                  final modifiedDate = fileStat.modified;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf, color: Colors.red[600]),
                      title: Text(
                        fileName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'גודל: ${fileSize} KB',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'נוצר: ${modifiedDate.day}/${modifiedDate.month}/${modifiedDate.year} ${modifiedDate.hour}:${modifiedDate.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: file.path));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('נתיב הקובץ הועתק ללוח'),
                              backgroundColor: Colors.blue[600],
                            ),
                          );
                        },
                        tooltip: 'העתק נתיב קובץ',
                      ),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: file.path));
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('נתיב הקובץ הועתק: $fileName'),
                            backgroundColor: Colors.green[600],
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final allPaths = catalogFiles.map((f) => f.path).join('\n');
                await Clipboard.setData(ClipboardData(text: allPaths));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('כל נתיבי הקבצים הועתקו ללוח'),
                    backgroundColor: Colors.blue[600],
                  ),
                );
              },
              icon: const Icon(Icons.copy_all),
              label: const Text('העתק הכל'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('סגור'),
            ),
          ],
        );
      },
    );
  }
}