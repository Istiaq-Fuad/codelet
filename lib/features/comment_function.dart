import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Add a comment to the post
Future<void> addComment(String postId, String commentText) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null || commentText.trim().isEmpty) return;

  final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

  final comment = {
    'commenterId': userId,
    'commentText': commentText,
    'timestamp': FieldValue.serverTimestamp(),
  };

  await postRef.update({
    'comments': FieldValue.arrayUnion([comment]),
  });
}