import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class PdfFileOperations {
  // Get the app directory path
  static Future<String> _getAppDirectoryPath() async {
    if (kIsWeb) {
      throw Exception('Web platform does not support local file storage');
    }
    
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/ASOfficeWeb');
    
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
      print('Created app directory: ${appDir.path}');
    }
    
    return appDir.path;
  }

  // Print PDF
  static Future<void> printPdf(pw.Document pdf, BuildContext context) async {
    try {
      final bytes = await pdf.save();
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הקטלוג נשלח להדפסה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error printing PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהדפסה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Print and save PDF
  static Future<void> printAndSave(pw.Document pdf, BuildContext context) async {
    try {
      await saveToAppFolder(pdf, context);
      await printPdf(pdf, context);
    } catch (e) {
      print('Error in print and save: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהדפסה ושמירה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save PDF to app folder
  static Future<void> saveToAppFolder(pw.Document pdf, BuildContext context) async {
    try {
      final bytes = await pdf.save();
      final timestamp = DateTime.now();
      final formattedTimestamp = '${timestamp.year}'
          '${timestamp.month.toString().padLeft(2, '0')}'
          '${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}'
          '${timestamp.minute.toString().padLeft(2, '0')}'
          '${timestamp.second.toString().padLeft(2, '0')}';
      
      final fileName = 'A_S_Office_Catalog_$formattedTimestamp.pdf';
      
      if (kIsWeb) {
        // For web platform - browser download
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('הקטלוג הורד בהצלחה: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'פתח תיקיית הורדות',
                textColor: Colors.white,
                onPressed: () {
                  _showWebDownloadInstructions(context, fileName);
                },
              ),
            ),
          );
        }
      } else {
        // For desktop/mobile - save to app directory
        final appDirectoryPath = await _getAppDirectoryPath();
        final file = File('$appDirectoryPath/$fileName');
        
        print('Saving PDF to app directory: ${file.path}');
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('הקטלוג נשמר בהצלחה!'),
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'תיקיית האפליקציה',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'פתח תיקייה',
                textColor: Colors.white,
                onPressed: () => _openAppFolder(context),
              ),
            ),
          );
        }
        
        print('PDF saved successfully to: ${file.path}');
        print('File size: ${await file.length()} bytes');
      }
    } catch (e) {
      print('Error saving PDF to app folder: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הקטלוג: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open app folder
  static Future<void> _openAppFolder(BuildContext context) async {
    try {
      if (kIsWeb) return;
      
      final appDirectoryPath = await _getAppDirectoryPath();
      
      if (Platform.isWindows) {
        await Process.run('explorer', [appDirectoryPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [appDirectoryPath]);
      } else if (Platform.isLinux) {
        try {
          await Process.run('xdg-open', [appDirectoryPath]);
        } catch (e) {
          try {
            await Process.run('nautilus', [appDirectoryPath]);
          } catch (e) {
            try {
              await Process.run('dolphin', [appDirectoryPath]);
            } catch (e) {
              throw Exception('לא ניתן לפתוח את סייר הקבצים');
            }
          }
        }
      }
    } catch (e) {
      print('Error opening app folder: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בפתיחת התיקייה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show web download instructions
  static void _showWebDownloadInstructions(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'הקובץ הורד בהצלחה',
            textDirection: TextDirection.rtl,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'שם הקובץ: $fileName',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              const Text(
                'הקובץ נשמר בתיקיית ההורדות של הדפדפן שלך.\n\nלמציאת הקובץ:',
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              const Text(
                '• Chrome: Ctrl+J או לחץ על אייקון ההורדות\n'
                '• Firefox: Ctrl+Shift+Y או תפריט הורדות\n'
                '• Safari: Option+Cmd+L או הצג הורדות\n'
                '• Edge: Ctrl+J או תפריט הורדות',
                style: TextStyle(fontSize: 12),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('הבנתי'),
            ),
          ],
        );
      },
    );
  }
}