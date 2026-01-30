import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dc1cl6kfe';
  static const String _uploadPreset = 'safeplate';

  static Uri _buildUploadUri() {
    return Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
  }

  static Future<String> uploadImage(
    File imageFile, {
    required String folder,
    String? publicId,
  }) async {
    try {
      final uri = _buildUploadUri();

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder;

      if (publicId != null && publicId.isNotEmpty) {
        request.fields['public_id'] = publicId;
      }

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(responseBody) as Map<String, dynamic>;
        final String? secureUrl = (data['secure_url'] ?? data['url']) as String?;
        if (secureUrl == null || secureUrl.isEmpty) {
          throw Exception('Resposta do Cloudinary sem URL válida.');
        }
        debugPrint('✅ Imagem enviada para Cloudinary: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('❌ Erro Cloudinary (${streamedResponse.statusCode}): $responseBody');
        throw Exception('Erro ao enviar imagem (Cloudinary): ${streamedResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exceção ao enviar imagem para Cloudinary: $e');
      rethrow;
    }
  }

  static Future<List<String>> uploadImages(
    List<File> imageFiles, {
    required String folder,
    String? namePrefix,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final suffix = DateTime.now().millisecondsSinceEpoch;
      final publicId = namePrefix != null && namePrefix.isNotEmpty
          ? '${namePrefix}_${i}_$suffix'
          : null;
      final url = await uploadImage(
        imageFiles[i],
        folder: folder,
        publicId: publicId,
      );
      urls.add(url);
    }

    return urls;
  }
}
