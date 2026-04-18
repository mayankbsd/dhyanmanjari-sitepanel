class PostModel {
  final String id;
  final String title;
  final String description;

  PostModel({
    required this.id,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      title: map['title'],
      description: map['description'],
    );
  }
}