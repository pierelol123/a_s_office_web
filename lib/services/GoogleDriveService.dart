import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const _scopes = [drive.DriveApi.driveFileScope];
  
  // Your actual Google Cloud service account credentials
  static const _credentials = {
    "type": "service_account",
    "project_id": "aswebproject",
    "private_key_id": "f4ed437c32443059c7707d476c8356d335d561d6",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDS9xpBm1X31rli\nUWa/NzkAXSwkmC2iRrE3mUWUdiSQ3/TgdWdQ5rnFpQASFqdKhhyr1boQpzZxTZpV\nsefRHk4O9qvJNtX90qcDO6nSVkyW1LGeMd8n6AaDgJC4cH19Z++o99odKAcYZb2j\nZMwtkbAdCWGsxzhKCbyjxnKoGRVEb04TSTPBNvVfbKf7ptbGOhG3iLU7edMATzmt\nrdw4wWbc0LADIPhPhAGEaasnGX6ZReOZnqErtmwKXhu8NE6FXrdmyS60UcTiYF+C\nRcdAmi8NG8b9r2HUu8di6iv6n+pO0FxRdJNMGh4PfhSQDfjb13npYOMJmfTjVdzy\ntB51MFdbAgMBAAECggEAFJsmPrpEJLfIgR31AesMRPN/gvjfnDYjdowgtmZDyWgs\nAbCgrXpGiFOcNNLETGHacxOmikc1k3jtAOnQ/CVloniIQa3QK8Fjpsvbw+ZssgmH\nFS3x33KpEDctQOwGld/iZ4gDZKMAQ8B29tAQUXMlgfCPUH0KYSZKUq+Ti2/HxVic\nV1vK4rJkxmS6H9ORme4LV/DVzt8MQnrCfZdMQSd3rBKgIdP0bDcDYD5j7HE5oAri\nGbFtkATld98Wt2mJrZa6dvbiWP7ru4SLSn4jH2QUl2hA/ctcQ0l/8dXZgNKV2vM4\njs36VN9aSUA9Vtvqb0aLXzb6CbsYwEnyeMAYc+58QQKBgQD5whXoCGK0amc/ayH3\nTF4n3jrpRHuUZJN7M/lpV7DmY3jAgxEbJL8RghNvXB6p+TfjIg17KC6r0rN5zMts\n4jS/zo31ThqvQV5HPBkeqT+/wuNuj6fUGozp1EFZ2aGzc9m9QSEVYWsGkZzR7jrl\ndRcBUoVh6I/OKabmCB3iTkLm2QKBgQDYPNNwd9TchRdN0/UPI7RZzKjNGKiXKzWZ\nj/mxnxAKz2uabuOEOAQIuh8J0sWxOM1zFjgu96XRhDcIev9CgWULyhZF1AIbPKUK\ntykTHwlwYHmYjD/HlSkH3k3u0OZFq7rrjbEiMfY0NVBjCOZF+7HqM7DZj/Uz+Uus\nvnCl45IXUwKBgCeSqQXqzjjn4xQZVXhpkUGf5JWxVCNfDD8pLQuT6WOXvzpBiiRS\n3jNX+NxcLD+iTUifzKMG6t4utGFIIbNO5Cy//Z4wkenS4a1HyHMjPgaUSpTqDh19\nV3Z1OyWRZh2Y7ZcfCq7okJyp1b8tkAdrVgnPmXK59o8j6l3oS1PgMpmBAoGALHNU\ng6oed7ZkM/t+RL5yNIN9r6uB/JFFU2vlSD4Kbi51UCm7W1KogaLA/qP1P5kNorrO\nkdkWnRswtO2Ty3gN7X59VZ1fUXoF803zg5q9tfwfAtzRv5VJ+fQY0R7gNzI2GnXm\nE8Fxewn6nGEX9QroZ9x4XkDZhvWYOMptHazKO0ECgYEAw9ejzVa2Ewfz/TndAZtk\nNg+3EUCvHdZad67bboWuk6ps0CXYykMnR/516BLhzv1o95FaTnOBCVDE47TahuZ+\nRrcPCVTnEaiG4BRJZmOtxhCEWWoP7s4gAGP/6yeF5krW6FgSOgdhy+9tOKgPgyEK\n7IG3WSvg95UWyMro7DaUTe4=\n-----END PRIVATE KEY-----\n",
    "client_email": "aswebserviceaccount@aswebproject.iam.gserviceaccount.com",
    "client_id": "100762925387956431435",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/aswebserviceaccount%40aswebproject.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
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