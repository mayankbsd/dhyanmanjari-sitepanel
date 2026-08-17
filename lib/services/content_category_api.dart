import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/content_category.dart';
import '../network/api_service.dart';

class ContentCategoryApi {
  static const String baseUrl =
      'https://dhayanmanjari.vercel.app/api';

  Future<List<ContentCategory>> getCategories(
      String type) async {
    final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/content-categories?type=$type',
        )
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load categories',
      );
    }

    final json = jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        json['message'] ??
            'Failed to load categories',
      );
    }

    final List list = json['data'] ?? [];

    return list
        .map(
          (e) => ContentCategory.fromJson(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();
  }
}