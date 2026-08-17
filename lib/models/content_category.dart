class ContentCategory {
  final int id;
  final String nameHi;
  final String nameEn;
  final String name;
  final String slug;
  final String type;
  final String icon;
  final int order;

  ContentCategory({
    required this.id,
    required this.nameHi,
    required this.nameEn,
    required this.name,
    required this.slug,
    required this.type,
    required this.icon,
    required this.order,
  });

  factory ContentCategory.fromJson(Map<String, dynamic> json) {
    final name = json['name'];

    return ContentCategory(
      id: (json['_id'] ?? json['id'] ?? 0) is num
          ? (json['_id'] ?? json['id'] ?? 0).toInt()
          : int.tryParse(
        (json['_id'] ?? json['id'] ?? '0').toString(),
      ) ??
          0,
      nameHi: name is Map
          ? (name['hi'] ?? '').toString()
          : '',
      nameEn: name is Map
          ? (name['en'] ?? '').toString()
          : '',
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      order: (json['order'] ?? 0) is num
          ? (json['order'] ?? 0).toInt()
          : 0,
    );
  }
}