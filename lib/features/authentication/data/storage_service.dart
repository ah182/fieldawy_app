import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// نتيجة رفع مؤقت
class TempUploadResult {
  final String secureUrl;
  final String publicId;
  const TempUploadResult({required this.secureUrl, required this.publicId});
}

class StorageService {
  static const _cloudName = 'dk8twnfrk'; // 👈 غيّر حسب حسابك
  static const _apiKey =
      '554622557218694'; // Optional if needed for delete
  static const _apiSecret = 'vFNW9PX3Rt-4ARIBFPnO4qqhV9I'; // Optional if needed

  final CloudinaryPublic _cloudinaryTemp = CloudinaryPublic(
    _cloudName,
    'fieldawy_unsigned_temp',
    cache: false,
  );

  final CloudinaryPublic _cloudinaryFinal = CloudinaryPublic(
    _cloudName,
    'background_removal',
    cache: false,
  );

  /// رفع الصورة مؤقتًا مع دعم progress
  Future<TempUploadResult?> uploadTempImage(
    File image, {
    void Function(double progress)? onProgress,
  }) async {
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

  /// رفع الصورة نهائيًا مع transformations مرنة
  Future<String?> uploadFinalImage(
    File image, {
    String transformation = 'e_background_removal,f_png,q_auto',
    void Function(double progress)? onProgress,
  }) async {
    try {
      final resp = await _cloudinaryFinal.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
       
      );

      const marker = '/upload/';
      final i = resp.secureUrl.indexOf(marker);
      if (i != -1) {
        return resp.secureUrl.replaceFirst(marker, '$marker$transformation/');
      }
      return resp.secureUrl;
    } catch (e) {
      print('❌ Final upload error: $e');
      return null;
    }
  }

  /// بناء رابط Preview معدل (on-the-fly)
  String buildPreviewUrl(String secureUrl,
      {String transformation = 'e_background_removal,f_png,q_auto'}) {
    const marker = '/upload/';
    final i = secureUrl.indexOf(marker);
    if (i == -1) return secureUrl;
    return secureUrl.replaceFirst(marker, '$marker$transformation/');
  }

  /// رفع مستند في فولدر محدد
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

  /// حذف الصورة المؤقتة عن طريق publicId (HTTP request)
  Future<bool> deleteTempImage(String publicId) async {
    try {
      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/resources/image/upload/$publicId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization':
              'Basic ' + base64Encode(utf8.encode('$_apiKey:$_apiSecret')),
        },
      );
      if (response.statusCode == 200) return true;
      print('Delete failed: ${response.body}');
      return false;
    } catch (e) {
      print('Error deleting temp image: $e');
      return false;
    }
  }
}

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
