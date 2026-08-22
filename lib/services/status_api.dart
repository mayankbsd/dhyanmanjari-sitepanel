import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/status_model.dart';
import '../network/api_service.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
class StatusApi {
  static const String baseUrl =
      'https://dhayanmanjari.vercel.app/api';

  Future<List<StatusModel>> getStatuses({
    int page = 1,
    int limit = 20,
    String language = 'hi',
    String categoryId = 'all',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/status'
          '?language=$language'
          '&page=$page'
          '&limit=$limit'
          '&categoryId=$categoryId',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load statuses');
    }

    final json = jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ?? 'Failed to load statuses',
      );
    }

    final List list = json['data'] ?? [];

    return list
        .map(
          (e) => StatusModel.fromJson(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();
  }

  Future<void> deleteStatus(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/status/$id'),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode >= 400 ||
        json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Failed to delete status',
      );
    }
  }

  Future<void> uploadStatus({
    required XFile media,
    required String titleHi,
    required String titleEn,
    required int categoryId,
    int durationSeconds = 0,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/status/upload',
    );

    debugPrint('================================');
    debugPrint('STATUS UPLOAD START');
    debugPrint('File name: ${media.name}');
    debugPrint('File path: ${media.path}');
    debugPrint('File mimeType: ${media.mimeType}');
    debugPrint('================================');

    // Web/Desktop/Mobile sab par chalega
    final bytes = await media.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('Selected file is empty');
    }

    // XFile ka MIME type
    String mimeType =
        media.mimeType?.toLowerCase() ?? '';

    // Agar picker MIME type nahi deta,
    // extension se determine karo.
    if (mimeType.isEmpty) {
      final extension =
      media.name.split('.').last.toLowerCase();

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;

        case 'png':
          mimeType = 'image/png';
          break;

        case 'webp':
          mimeType = 'image/webp';
          break;

        case 'gif':
          mimeType = 'image/gif';
          break;

        case 'mp4':
          mimeType = 'video/mp4';
          break;

        case 'mov':
          mimeType = 'video/quicktime';
          break;

        case 'webm':
          mimeType = 'video/webm';
          break;

        case 'avi':
          mimeType = 'video/x-msvideo';
          break;

        case 'mkv':
          mimeType = 'video/x-matroska';
          break;

        default:
          throw Exception(
            'Unsupported file type: ${media.name}',
          );
      }
    }

    debugPrint('Final MIME type: $mimeType');
    debugPrint('File size: ${bytes.length} bytes');

    final parts = mimeType.split('/');

    if (parts.length != 2 ||
        (parts[0] != 'image' &&
            parts[0] != 'video')) {
      throw Exception(
        'Only image and video files are allowed',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.headers['Authorization'] =
        ApiConstants.token;

    request.fields['titleHi'] = titleHi;
    request.fields['titleEn'] = titleEn;
    request.fields['categoryId'] =
        categoryId.toString();
    request.fields['durationSeconds'] =
        durationSeconds.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'media',
        bytes,
        filename: media.name,
        contentType: http.MediaType(
          parts[0],
          parts[1],
        ),
      ),
    );

    debugPrint('Sending multipart request...');

    final streamedResponse =
    await request.send();

    final response =
    await http.Response.fromStream(
      streamedResponse,
    );

    debugPrint(
      'Status code: ${response.statusCode}',
    );

    debugPrint(
      'Response: ${response.body}',
    );

    if (response.statusCode >= 400) {
      String message;

      try {
        final json =
        jsonDecode(response.body);

        message =
            json['message']?.toString() ??
                json['error']?.toString() ??
                'Upload failed';
      } catch (_) {
        // Backend HTML/text response
        message = response.body.isNotEmpty
            ? response.body
            : 'Upload failed';
      }

      throw Exception(message);
    }

    try {
      final json =
      jsonDecode(response.body);

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              json['error'] ??
              'Upload failed',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Invalid server response',
      );
    }
  }
  Future<void> updateStatus({
    required int id,
    XFile? media,
    required String titleHi,
    required String titleEn,
    required int categoryId,
    required int durationSeconds,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/status/$id',
    );

    final request = http.MultipartRequest(
      'PUT',
      uri,
    );

    request.headers.addAll({
      'Authorization': ApiConstants.token,
    });

    request.fields['titleHi'] = titleHi;
    request.fields['titleEn'] = titleEn;
    request.fields['categoryId'] =
        categoryId.toString();
    request.fields['durationSeconds'] =
        durationSeconds.toString();

    // Edit mein media optional
    if (media != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          media.path,
        ),
      );
    }

    final streamedResponse =
    await request.send();

    final response =
    await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['message'] ??
            'Status update failed',
      );
    }
  }
  Future<void> uploadMultipleStatus({
    required List<XFile> media,
    required String titleHi,
    required String titleEn,
    required int categoryId,
    int durationSeconds = 0,
  }) async {
    if (media.isEmpty) {
      throw Exception(
        'At least one media file is required',
      );
    }

    final url =
        '${ApiConstants.baseUrl}/status/upload-multiple';

    debugPrint(
      '========================================',
    );
    debugPrint(
      'MULTIPLE STATUS UPLOAD',
    );
    debugPrint(
      'URL: $url',
    );
    debugPrint(
      'FILES: ${media.length}',
    );
    debugPrint(
      '========================================',
    );

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );

    // =========================================
    // HEADERS
    // =========================================

    request.headers['Authorization'] =
        ApiConstants.token;

    // =========================================
    // FIELDS
    // =========================================

    request.fields['titleHi'] = titleHi;

    request.fields['titleEn'] = titleEn;

    request.fields['categoryId'] =
        categoryId.toString();

    request.fields['durationSeconds'] =
        durationSeconds.toString();

    // =========================================
    // MULTIPLE FILES
    // =========================================

    for (final file in media) {
      debugPrint(
        'Reading file: ${file.name}',
      );

      final bytes =
      await file.readAsBytes();

      debugPrint(
        'File size: ${bytes.length} bytes',
      );

      if (bytes.isEmpty) {
        throw Exception(
          'Unable to read file: ${file.name}',
        );
      }

      // =======================================
      // DETECT MIME TYPE
      // =======================================

      final mimeType =
      lookupMimeType(file.name);

      debugPrint(
        'MIME TYPE: $mimeType',
      );

      if (mimeType == null) {
        throw Exception(
          'Unable to detect file type: '
              '${file.name}',
        );
      }

      final parts =
      mimeType.split('/');

      if (parts.length != 2) {
        throw Exception(
          'Invalid MIME type: $mimeType',
        );
      }

      final mainType =
      parts[0];

      final subType =
      parts[1];

      // =======================================
      // ONLY IMAGE / VIDEO
      // =======================================

      if (mainType != 'image' &&
          mainType != 'video') {
        throw Exception(
          'Only image and video files are allowed: '
              '${file.name}',
        );
      }

      // =======================================
      // HTTP CONTENT TYPE
      // =======================================

      final contentType =
      MediaType(
        mainType,
        subType,
      );

      // =======================================
      // ADD MULTIPART FILE
      // =======================================

      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          bytes,
          filename: file.name,
          contentType: contentType,
        ),
      );

      debugPrint(
        'Added: ${file.name} '
            '($mimeType)',
      );
    }

    // =========================================
    // SEND
    // =========================================

    debugPrint(
      'Sending multipart request...',
    );

    final streamedResponse =
    await request.send();

    final response =
    await http.Response.fromStream(
      streamedResponse,
    );

    // =========================================
    // RESPONSE LOG
    // =========================================

    debugPrint(
      'Response status: '
          '${response.statusCode}',
    );

    debugPrint(
      'Response body: '
          '${response.body}',
    );

    // =========================================
    // SUCCESS
    // =========================================

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    // =========================================
    // ERROR
    // =========================================

    String message =
        'Multiple status upload failed '
        '(${response.statusCode})';

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map &&
          decoded['message'] != null) {
        message =
            decoded['message'].toString();
      }
    } catch (_) {
      message =
      'Server returned non-JSON response '
          '(${response.statusCode})';
    }

    throw Exception(message);
  }
  }