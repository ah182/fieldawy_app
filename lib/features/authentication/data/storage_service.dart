import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// نتيجة رفع مؤقت
class TempUploadResult {
  final String secureUrl;
  final String publicId;
  const TempUploadResult({required this.secureUrl, required this.publicId});
}

class StorageService {
  static const _cloudName = 'dk8twnfrk'; // 👈 غيّر حسب حسابك

  // ⏳ بريسيت مؤقت (unsigned + auto-delete)
  final CloudinaryPublic _cloudinaryTemp = CloudinaryPublic(
    _cloudName,
    'fieldawy_unsigned_temp',
    cache: false,
  );

  // ✅ بريسيت نهائي (background_removal + unsigned)
  final CloudinaryPublic _cloudinaryFinal = CloudinaryPublic(
    _cloudName,
    'background_removal',
    cache: false,
  );

  /// A function to upload a document image to a specific folder in Cloudinary.
  /// This is a simple, direct upload.
  Future<String?> uploadDocument(File image, String folderName) async {
    try {
      final response = await _cloudinaryFinal.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folderName,
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Error uploading document to Cloudinary: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error uploading document: $e');
      return null;
    }
  }

  /// رفع الصورة مؤقتًا
  Future<TempUploadResult?> uploadTempImage(File image) async {
    try {
      final resp = await _cloudinaryTemp.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return TempUploadResult(
        secureUrl: resp.secureUrl,
        publicId: resp.publicId,
      );
    } catch (e) {
      print('❌ Temp upload error: $e');
      return null;
    }
  }

  /// بناء رابط Preview معدل (on-the-fly)
  String buildPreviewUrl(String secureUrl,
      {String transformation = 'e_background_removal,f_auto,q_auto'}) {
    const marker = '/upload/';
    final i = secureUrl.indexOf(marker);
    if (i == -1) return secureUrl;
    return secureUrl.replaceFirst(marker, '$marker$transformation/');
  }

  /// رفع الصورة نهائيًا
  Future<String?> uploadFinalImage(File image) async {
    try {
      final resp = await _cloudinaryFinal.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return resp.secureUrl;
    } catch (e) {
      print('❌ Final upload error: $e');
      return null;
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
