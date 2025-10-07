import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// LocalImageService saves images to the app's documents directory and returns
/// a local file path (absolute). Use Image.file(File(path)) to render.
class LocalImageService {
  /// Saves [source] file into an app-managed images folder and returns its path.
  static Future<String> saveImage(File source, {String? nameHint}) async {
    try {
      // Check if source file exists
      if (!await source.exists()) {
        throw 'Source image file does not exist: ${source.path}';
      }

      // Check source file size
      final fileSize = await source.length();
      if (fileSize == 0) {
        throw 'Source image file is empty';
      }

      print('📱 Saving image locally - Size: ${fileSize} bytes');

      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      print('📁 App documents directory: ${dir.path}');
      
      // Create images subfolder
      final imagesDir = Directory(p.join(dir.path, 'images'));
      if (!await imagesDir.exists()) {
        try {
          await imagesDir.create(recursive: true);
          print('📁 Created images directory: ${imagesDir.path}');
        } catch (e) {
          throw 'Failed to create images directory: $e';
        }
      }

      // Generate safe filename
      final ext = p.extension(source.path).isNotEmpty
          ? p.extension(source.path)
          : '.jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = (nameHint ?? p.basenameWithoutExtension(source.path))
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          .toLowerCase();
      final fileName = '${safeName}_$timestamp$ext';
      final destPath = p.join(imagesDir.path, fileName);

      print('📱 Copying to: $destPath');

      // Copy file to destination
      try {
        await source.copy(destPath);
        
        // Verify the copied file exists and has content
        final copiedFile = File(destPath);
        if (!await copiedFile.exists()) {
          throw 'File was not copied successfully';
        }
        
        final copiedSize = await copiedFile.length();
        if (copiedSize != fileSize) {
          throw 'File copy incomplete - Original: $fileSize bytes, Copied: $copiedSize bytes';
        }
        
        print('✅ Image saved successfully: $destPath (${copiedSize} bytes)');
        return destPath; // absolute local path
      } catch (e) {
        throw 'Failed to copy image file: $e';
      }
    } catch (e) {
      print('❌ Error saving image locally: $e');
      rethrow;
    }
  }

  /// Deletes a previously saved image by absolute [path].
  static Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted local image: $path');
      } else {
        print('⚠️ Local image file not found for deletion: $path');
      }
    } catch (e) {
      print('❌ Error deleting local image: $e');
      // best-effort - don't throw, just log
    }
  }

  /// Gets the local images directory path for debugging
  static Future<String> getImagesDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'images');
  }

  /// Lists all locally saved images for debugging
  static Future<List<String>> listLocalImages() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'images'));
      
      if (!await imagesDir.exists()) {
        return [];
      }
      
      final files = await imagesDir.list().toList();
      return files
          .where((entity) => entity is File)
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('❌ Error listing local images: $e');
      return [];
    }
  }
}
