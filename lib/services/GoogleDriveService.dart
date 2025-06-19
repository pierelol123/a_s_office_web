import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const _scopes = [drive.DriveApi.driveFileScope];
  static const String _shareWithEmail = 'aswebacc12@gmail.com'; // The Gmail account to share with
  
  // Your actual Google Cloud service account credentials


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
      print('=== Starting Google Drive Upload ===');
      print('File name: $fileName');
      print('File size: ${imageBytes.length} bytes');
      
      // Authenticate using your service account
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      print('Service account credentials loaded');
      
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      print('Authentication successful');
      
      // Create Drive API instance
      final driveApi = drive.DriveApi(client);
      print('Drive API instance created');
      
      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..description = 'Image uploaded from A&S Office Web App'
        ..parents = folderId != null ? [folderId] : null; // Set parent folder if provided
    
      // Create media
      final contentType = _getContentType(fileName);
      print('Content type: $contentType');
      
      final media = drive.Media(
        Stream.fromIterable([imageBytes]),
        imageBytes.length,
        contentType: contentType,
      );
      
      print('Starting file upload...');
      
      // Upload file
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
      
      print('File uploaded successfully with ID: ${response.id}');
      
      if (response.id == null) {
        throw Exception('Upload succeeded but no file ID returned');
      }
      
      // Set up permissions - both public and specific Gmail account
      print('Setting file permissions...');
      
      // 1. Make file publicly viewable (for general access)
      try {
        await driveApi.permissions.create(
          drive.Permission()
            ..role = 'reader'
            ..type = 'anyone',
          response.id!,
        );
        print('✅ Public read permission set successfully');
      } catch (e) {
        print('⚠️ Warning: Could not set public permission: $e');
      }
      
      // 2. Share specifically with aswebacc12@gmail.com with editor permissions
      try {
        await driveApi.permissions.create(
          drive.Permission()
            ..role = 'writer' // Can edit the file
            ..type = 'user'
            ..emailAddress = _shareWithEmail,
          response.id!,
          sendNotificationEmail: false, // Don't send email notification
        );
        print('✅ File shared with $_shareWithEmail (writer permissions)');
      } catch (e) {
        print('⚠️ Warning: Could not share with $_shareWithEmail: $e');
        // Try with reader permissions instead
        try {
          await driveApi.permissions.create(
            drive.Permission()
              ..role = 'reader' // Can only view the file
              ..type = 'user'
              ..emailAddress = _shareWithEmail,
            response.id!,
            sendNotificationEmail: false,
          );
          print('✅ File shared with $_shareWithEmail (reader permissions)');
        } catch (e2) {
          print('❌ Failed to share with $_shareWithEmail: $e2');
        }
      }
      
      // Generate the direct view URL
      final directUrl = 'https://drive.google.com/uc?export=view&id=${response.id}';
      print('Generated URL: $directUrl');
      
      // Close the HTTP client
      client.close();
      print('=== Upload completed successfully ===');
      
      return directUrl;
      
    } catch (e, stackTrace) {
      print('❌ Error uploading to Google Drive: $e');
      print('Stack trace: $stackTrace');
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
  
  // New method to specifically upload to the aswebimages folder and share with Gmail account
  static Future<String?> uploadImageToAswebFolder({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      print('=== Uploading to aswebimages folder ===');
      
      // First find the aswebimages folder
      final folderId = await findAswebImagesFolder();
      if (folderId == null) {
        print('❌ Cannot upload: aswebimages folder not found');
        return null;
      }
      
      print('Found aswebimages folder ID: $folderId');
      
      // Upload to the specific folder
      return await uploadImageToDrive(
        imageBytes: imageBytes,
        fileName: fileName,
        folderId: folderId,
      );
      
    } catch (e) {
      print('❌ Error uploading to aswebimages folder: $e');
      return null;
    }
  }
  
  // Method to share an existing file with the Gmail account
  static Future<bool> shareFileWithGmailAccount(String fileId) async {
    try {
      print('=== Sharing file $fileId with $_shareWithEmail ===');
      
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      final driveApi = drive.DriveApi(client);
      
      // Share with writer permissions
      await driveApi.permissions.create(
        drive.Permission()
          ..role = 'writer'
          ..type = 'user'
          ..emailAddress = _shareWithEmail,
        fileId,
        sendNotificationEmail: false,
      );
      
      client.close();
      print('✅ File shared successfully with $_shareWithEmail');
      return true;
      
    } catch (e) {
      print('❌ Error sharing file: $e');
      return false;
    }
  }
  
  // Method to check current permissions on a file
  static Future<void> checkFilePermissions(String fileId) async {
    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      final driveApi = drive.DriveApi(client);
      
      final permissions = await driveApi.permissions.list(fileId);
      
      print('=== File Permissions for $fileId ===');
      if (permissions.permissions != null) {
        for (var permission in permissions.permissions!) {
          print('Type: ${permission.type}, Role: ${permission.role}, Email: ${permission.emailAddress}');
        }
      } else {
        print('No permissions found');
      }
      
      client.close();
      
    } catch (e) {
      print('❌ Error checking file permissions: $e');
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

  // Test method to verify Gmail account sharing works
  static Future<void> testGmailAccountSharing() async {
    try {
      print('=== Testing Gmail Account Sharing ===');
      print('Target Gmail account: $_shareWithEmail');
      
      // You can call this method after uploading a file to test if sharing works
      print('To test sharing:');
      print('1. Upload an image using uploadImageToDrive()');
      print('2. Check if $_shareWithEmail receives access');
      print('3. Verify the file appears in their Google Drive');
      
    } catch (e) {
      print('❌ Error in Gmail sharing test: $e');
    }
  }
}