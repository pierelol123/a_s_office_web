import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const _scopes = [drive.DriveApi.driveFileScope];
  
  // Your actual Google Cloud service account credentials
  static const _credentials = {

  };

  // Add method to find the shared folder
  static Future<String?> findAswebImagesFolder() async {
    try {
      print('=== Starting folder search ===');
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      print('Service account credentials loaded successfully');
      
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      print('Client authenticated successfully');
      
      final driveApi = drive.DriveApi(client);
      print('Drive API instance created');
      
      // First, let's see ALL folders the service account can access
      print('Searching for ALL folders accessible to service account...');
      final allFoldersResponse = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.folder'",
        spaces: 'drive',
        pageSize: 100, // Get more results
      );
      
      print('Total folders found: ${allFoldersResponse.files?.length ?? 0}');
      if (allFoldersResponse.files != null) {
        for (var folder in allFoldersResponse.files!) {
          print('Folder: "${folder.name}" (ID: ${folder.id})');
        }
      }
      
      // Now search specifically for "aswebimages"
      print('Searching specifically for "aswebimages" folder...');
      final response = await driveApi.files.list(
        q: "name='aswebimages' and mimeType='application/vnd.google-apps.folder'",
        spaces: 'drive',
        pageSize: 100,
      );
      
      print('Search query: name=\'aswebimages\' and mimeType=\'application/vnd.google-apps.folder\'');
      print('Results for aswebimages search: ${response.files?.length ?? 0}');
      
      // Also try case-insensitive search
      print('Trying case-insensitive search...');
      final caseInsensitiveResponse = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.folder'",
        spaces: 'drive',
        pageSize: 100,
      );
      
      if (caseInsensitiveResponse.files != null) {
        for (var folder in caseInsensitiveResponse.files!) {
          if (folder.name?.toLowerCase().contains('aswebimages') == true ||
              folder.name?.toLowerCase().contains('asweb') == true ||
              folder.name?.toLowerCase().contains('images') == true) {
            print('Potential match found: "${folder.name}" (ID: ${folder.id})');
          }
        }
      }
      
      client.close();
      
      if (response.files != null && response.files!.isNotEmpty) {
        final folderId = response.files!.first.id;
        print('✅ Found aswebimages folder with ID: $folderId');
        return folderId;
      } else {
        print('❌ aswebimages folder not found. Possible issues:');
        print('1. Folder name might be different (case sensitive)');
        print('2. Folder not shared with service account');
        print('3. Service account doesn\'t have proper permissions');
        print('4. Folder might be in a different location');
        return null;
      }
      
    } catch (e) {
      print('❌ Error finding aswebimages folder: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  static Future<String?> uploadImageToDrive({
    required Uint8List imageBytes,
    required String fileName,
    String? folderId,
  }) async {
    try {
      print('Starting upload to Google Drive...');
      
      // Authenticate using your service account
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      
      print('Authentication successful');
      
      // Create Drive API instance
      final driveApi = drive.DriveApi(client);
      
      // Create file metadata - upload to root
      final driveFile = drive.File()
        ..name = fileName;
    
      // Create media
      final media = drive.Media(
        Stream.fromIterable([imageBytes]),
        imageBytes.length,
        contentType: _getContentType(fileName),
      );
      
      print('Uploading file: $fileName to service account drive');
      
      // Upload file
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
      
      print('File uploaded with ID: ${response.id}');
      
      // Make file publicly viewable
      await driveApi.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        response.id!,
      );
    
      // SHARE WITH YOUR PERSONAL ACCOUNT - Replace with your actual email
      await driveApi.permissions.create(
        drive.Permission()
          ..role = 'writer' // or 'reader' if you prefer
          ..type = 'user'
          ..emailAddress = 'aswebacc12@gmail.com', // REPLACE THIS
        response.id!,
      );
    
      print('File shared with your personal account');
      print('File permissions set to public');
      
      // Return the direct view URL
      final directUrl = 'https://drive.google.com/uc?export=view&id=${response.id}';
      print('Generated URL: $directUrl');
      
      // Close the HTTP client
      client.close();
      
      return directUrl;
      
    } catch (e) {
      print('Error uploading to Google Drive: $e');
      return null;
    }
  }
  
  // Method to list all images in the aswebimages folder
  static Future<List<drive.File>> listImagesInAswebFolder() async {
    try {
      final aswebImagesFolderId = await findAswebImagesFolder();
      if (aswebImagesFolderId == null) {
        print('aswebimages folder not found');
        return [];
      }
      
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      final driveApi = drive.DriveApi(client);
      
      // List all image files in the aswebimages folder
      final response = await driveApi.files.list(
        q: "'$aswebImagesFolderId' in parents and mimeType contains 'image/'",
        spaces: 'drive',
        orderBy: 'createdTime desc', // Most recent first
      );
      
      client.close();
      return response.files ?? [];
      
    } catch (e) {
      print('Error listing images in aswebimages folder: $e');
      return [];
    }
  }
  
  static String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  // Also add a test method to verify service account access
  static Future<void> testServiceAccountAccess() async {
    try {
      print('=== Testing Service Account Access ===');
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      final driveApi = drive.DriveApi(client);
      
      // Test basic access
      final aboutResponse = await driveApi.about.get($fields: 'user,storageQuota');
      print('Service account email: ${aboutResponse.user?.emailAddress}');
      print('Display name: ${aboutResponse.user?.displayName}');
      
      // List recent files
      final recentFiles = await driveApi.files.list(
        pageSize: 10,
        orderBy: 'modifiedTime desc',
      );
      
      print('Recent files accessible to service account:');
      if (recentFiles.files != null) {
        for (var file in recentFiles.files!) {
          print('- ${file.name} (${file.mimeType}) - ID: ${file.id}');
        }
      } else {
        print('No files found - service account might not have access to any files');
      }
      
      client.close();
      
    } catch (e) {
      print('❌ Service account access test failed: $e');
    }
  }
}