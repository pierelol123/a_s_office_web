class ImageUtils {
  static String convertGoogleDriveUrl(String url) {
    // Check if it's a Google Drive link
    if (url.contains('drive.google.com')) {
      // Extract the file ID from different Google Drive URL formats
      String? fileId;
      
      // Format: https://drive.google.com/file/d/FILE_ID/view?usp=sharing
      if (url.contains('/file/d/')) {
        final regex = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
        final match = regex.firstMatch(url);
        fileId = match?.group(1);
      }
      
      // Format: https://drive.google.com/open?id=FILE_ID
      if (fileId == null && url.contains('id=')) {
        final regex = RegExp(r'id=([a-zA-Z0-9_-]+)');
        final match = regex.firstMatch(url);
        fileId = match?.group(1);
      }
      
      // Convert to direct image URL
      if (fileId != null) {
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    }
    
    // Return original URL if it's not a Google Drive link or conversion failed
    return url;
  }
  
  static bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    // Check for common image extensions
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    
    // Check if URL ends with image extension or is a Google Drive link
    return imageExtensions.any((ext) => lowerUrl.contains(ext)) || 
           url.contains('drive.google.com') ||
           url.contains('uc?export=view&id=');
  }
}