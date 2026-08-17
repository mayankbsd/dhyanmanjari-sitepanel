class StatusModel {
  final int id;
  final String title;
  final String mediaType;
  final String mediaUrl;
  final String thumbnailUrl;
  final int durationSeconds;
  final bool isActive;
  final Map<String, dynamic>? category;
  final String? createdAt;

  StatusModel({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.isActive,
    this.category,
    this.createdAt,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: (json['_id'] ?? 0) is num
          ? (json['_id'] ?? 0).toInt()
          : int.tryParse('${json['_id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? 'image').toString(),
      mediaUrl: (json['mediaUrl'] ?? '').toString(),
      thumbnailUrl: (json['thumbnailUrl'] ?? '').toString(),
      durationSeconds: (json['durationSeconds'] ?? 0) is num
          ? (json['durationSeconds'] ?? 0).toInt()
          : 0,
      isActive: json['isActive'] == true,
      category: json['category'] is Map
          ? Map<String, dynamic>.from(json['category'])
          : null,
      createdAt: json['createdAt']?.toString(),
    );
  }

  String get categoryName {
    if (category == null) return 'Uncategorized';

    final name = category!['name'];

    if (name is String) return name;

    if (name is Map) {
      return (name['hi'] ?? name['en'] ?? '').toString();
    }

    return '';
  }
}