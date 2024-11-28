import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> likePost(String postId) async {
  DocumentReference postRef =
      FirebaseFirestore.instance.collection('posts').doc(postId);
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot postSnapshot = await transaction.get(postRef);
    int newLikes = (postSnapshot['likes'] ?? 0) + 1;
    transaction.update(postRef, {'likes': newLikes});
  });
}

// Add a like to the post
Future<void> toggleLike(String postId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
  final postSnapshot = await postRef.get();

  if (postSnapshot.exists) {
    List<String> likes = List<String>.from(postSnapshot['likes'] ?? []);

    if (likes.contains(userId)) {
      // If already liked, remove the like
      likes.remove(userId);
    } else {
      // Add like if not already liked
      likes.add(userId);
    }

    await postRef.update({'likes': likes});
  }
}
