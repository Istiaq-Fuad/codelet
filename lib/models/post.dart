class PostModel {
  String id;
  String title;
  List<dynamic> content;
  String? imageUrl;
  String authorId;
  List<String> likes; // List of user IDs who liked the post
  List<Map<String, dynamic>> comments; // List of comments
  List<String> categories;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.authorId,
    this.likes = const [], // Initialize with an empty list
    this.comments = const [], // Initialize with an empty list
    this.categories = const [],
  });

  factory PostModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PostModel(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? [],
      imageUrl: data['imageUrl'],
      authorId: data['authorId'] ?? '',
      likes: data['likes'] is List
          ? List<String>.from(data['likes'])
          : [], // Default to empty list if null
      comments: data['comments'] != null
          ? List<Map<String, dynamic>>.from(data['comments'])
          : [],
      categories: data['categories'] != null
          ? List<String>.from(data['categories'])
          : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'likes': likes, // Save as list of user IDs
      'comments': comments,
      'categories': categories,
    };
  }
}
