import 'dart:io'; // ✅ تم التصحيح
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dk8twnfrk', // ← غيرها بالقيمة الحقيقية
    'fieldawy_unsigned', // اسم الـ Upload Preset
    cache: false,
  );

  /// A function to upload an image to a specific folder in Cloudinary
  Future<String?> uploadDocument(File image, String folderName) async {
    try {
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image, // ✅ أضفنا نوع الملف
          folder: folderName,
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Error uploading document to Cloudinary: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
