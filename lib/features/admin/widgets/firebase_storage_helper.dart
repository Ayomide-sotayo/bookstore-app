import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FirebaseStorageHelper {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Compress and upload image to Firebase Storage
  static Future<String?> uploadBookImage(File imageFile) async {
    try {
      // Step 1: Compress the image
      final compressedImage = await _compressImage(imageFile);
      if (compressedImage == null) {
        throw Exception('Failed to compress image');
      }

      // Step 2: Create storage reference
      final fileName = 'book_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('book_images/$fileName');

      // Step 3: Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=31536000', // Cache for 1 year
        customMetadata: {
          'uploaded_by': 'admin',
          'upload_time': DateTime.now().toIso8601String(),
          'compressed': 'true',
        },
      );

      // Step 4: Upload with retry mechanism
      TaskSnapshot? snapshot;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          final uploadTask = ref.putData(compressedImage, metadata);
          
          // Set up timeout
          snapshot = await uploadTask.timeout(
            const Duration(minutes: 3),
            onTimeout: () {
              uploadTask.cancel();
              throw Exception('Upload timeout');
            },
          );
          
          break; // Success, exit retry loop
          
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow; // Max retries reached, throw the error
          }
          
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }

      if (snapshot == null) {
        throw Exception('Upload failed after $maxRetries attempts');
      }

      // Step 5: Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;

    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  /// Compress image to reduce file size
  static Future<Uint8List?> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      print('Image compression failed: $e');
      // Fallback: read file directly if compression fails
      return await file.readAsBytes();
    }
  }

  /// Handle Firebase Storage exceptions with user-friendly messages
  static Exception _handleFirebaseException(FirebaseException e) {
    String message;
    
    switch (e.code) {
      case 'storage/canceled':
        message = 'Upload was cancelled. Please try again.';
        break;
      case 'storage/unknown':
        message = 'Upload failed due to unknown error. Check your internet connection.';
        break;
      case 'storage/object-not-found':
        message = 'File not found. Please select the image again.';
        break;
      case 'storage/bucket-not-found':
        message = 'Storage configuration error. Contact support.';
        break;
      case 'storage/project-not-found':
        message = 'Firebase project not found. Contact support.';
        break;
      case 'storage/quota-exceeded':
        message = 'Storage limit reached. Contact administrator.';
        break;
      case 'storage/unauthenticated':
        message = 'Authentication required. Please log in again.';
        break;
      case 'storage/unauthorized':
        message = 'Permission denied. Contact administrator.';
        break;
      case 'storage/retry-limit-exceeded':
        message = 'Upload failed after multiple attempts. Check your connection.';
        break;
      case 'storage/invalid-checksum':
        message = 'File corrupted during upload. Please try again.';
        break;
      case 'storage/server-file-wrong-size':
        message = 'Server error during upload. Please try again.';
        break;
      default:
        message = 'Upload failed: ${e.message ?? 'Unknown error'}';
    }
    
    return Exception(message);
  }

  /// Delete image from Firebase Storage
  static Future<bool> deleteBookImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } on FirebaseException catch (e) {
      print('Delete error: ${e.code} - ${e.message}');
      // Don't throw error for delete operations
      // as the book can still be deleted even if image deletion fails
      return false;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  /// Check if file size is within limits
  static bool isFileSizeValid(File file, int maxSizeInMB) {
    final fileSizeInBytes = file.lengthSync();
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return fileSizeInBytes <= maxSizeInBytes;
  }

  /// Get file size in human readable format
  static String getFileSizeString(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}