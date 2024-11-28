import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updatePost({
  required String postId,
  required String title,
  required List<String> categories,
  required dynamic content,
  String? imageUrl,
}) async {
  try {
    // Reference to the specific document in the "posts" collection
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    // Data to update in the Firestore document
    final data = {
      'title': title,
      'categories': categories,
      'content': content,
      'imageUrl': imageUrl, // Can be null if no image update is needed
      'updatedAt': FieldValue.serverTimestamp(), // Optional: for tracking last update time
    };

    // Remove any null values from the data before updating Firestore
    data.removeWhere((key, value) => value == null);

    // Update the document with the provided data
    await postRef.update(data);
    print("Post updated successfully");
  } catch (e) {
    print("Failed to update post: $e");
  }
}
