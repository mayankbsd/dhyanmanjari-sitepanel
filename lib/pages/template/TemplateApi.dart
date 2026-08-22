import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../network/api_service.dart';



class TemplateApi {
  static const String baseUrl =
      'https://dhayanmanjari.vercel.app/api';

  // =========================================================
  // MULTIPLE TEMPLATE UPLOAD
  // =========================================================

  Future<void> uploadMultipleTemplates({
    required List<XFile> images,
    required String titleHi,
    required String titleEn,
    required int categoryId,
    String textHi = '',
    String textEn = '',
  }) async {
    if (images.isEmpty) {
      throw Exception(
        'At least one template image is required',
      );
    }

    final url =
        '${ApiConstants.baseUrl}/templates/upload-multiple';

    debugPrint('========================================');
    debugPrint('MULTIPLE TEMPLATE UPLOAD');
    debugPrint('URL: $url');
    debugPrint('FILES: ${images.length}');
    debugPrint('========================================');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );

    // =========================================
    // HEADER
    // =========================================

    request.headers['Authorization'] =
        ApiConstants.token;

    // =========================================
    // FIELDS
    // =========================================

    request.fields['titleHi'] =
        titleHi.trim();

    request.fields['titleEn'] =
        titleEn.trim();

    request.fields['categoryId'] =
        categoryId.toString();

    // Agar backend me text fields hain
    // to ye bhej sakte ho.
    if (textHi.trim().isNotEmpty) {
      request.fields['textHi'] =
          textHi.trim();
    }

    if (textEn.trim().isNotEmpty) {
      request.fields['textEn'] =
          textEn.trim();
    }

    // =========================================
    // MULTIPLE IMAGES
    // IMPORTANT: field name = image
    // =========================================

    for (final file in images) {
      debugPrint(
        'Reading: ${file.name}',
      );

      final bytes =
      await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception(
          'Unable to read file: ${file.name}',
        );
      }

      String? mimeType =
      file.mimeType?.toLowerCase();

      mimeType ??=
          lookupMimeType(file.name);

      if (mimeType == null) {
        throw Exception(
          'Unable to detect file type: ${file.name}',
        );
      }

      final parts =
      mimeType.split('/');

      if (parts.length != 2 ||
          parts[0] != 'image') {
        throw Exception(
          'Only image files are allowed: ${file.name}',
        );
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: file.name,
          contentType: MediaType(
            parts[0],
            parts[1],
          ),
        ),
      );

      debugPrint(
        'Added: ${file.name} ($mimeType)',
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

    debugPrint(
      'Status: ${response.statusCode}',
    );

    debugPrint(
      'Response: ${response.body}',
    );

    // =========================================
    // ERROR
    // =========================================

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Multiple template upload failed '
          '(${response.statusCode})';

      try {
        final json =
        jsonDecode(response.body);

        if (json is Map &&
            json['message'] != null) {
          message =
              json['message'].toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          message = response.body;
        }
      }

      throw Exception(message);
    }

    // =========================================
    // SUCCESS RESPONSE
    // =========================================

    try {
      final json =
      jsonDecode(response.body);

      if (json is Map &&
          json['success'] == false) {
        throw Exception(
          json['message'] ??
              'Template upload failed',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      // Non-JSON successful response ko
      // failure mat samjho.
    }
  }
}