import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:codelet/models/post.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  String? replyingToCommentId;

  // Cache to store usernames by userId
  final Map<String, String> _usernamesCache = {};

  Future<PostModel?> _getPostData() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();
    if (doc.exists) {
      return PostModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> toggleLike(PostModel post) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      if (post.likes.contains(userId)) {
        post.likes.remove(userId);
      } else {
        post.likes.add(userId);
      }
    });

    await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
      'likes': post.likes,
    });
  }

  Future<String> _getUsername(String userId) async {
    if (_usernamesCache.containsKey(userId)) {
      return _usernamesCache[userId]!;
    }
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final username = userDoc.data()?['username'] ?? 'Unknown';
    _usernamesCache[userId] = username;
    return username;
  }

  Future<void> addComment(String text, PostModel post) async {
    final newComment = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      post.comments.add(newComment);
    });

    await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
      'comments': post.comments,
    });

    _commentController.clear();
  }

  Widget _buildComment(PostModel post, Map<String, dynamic> comment,
      {String? repliedToUsername}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FutureBuilder<String>(
        future: _getUsername(comment['userId']),
        builder: (context, snapshot) {
          final username = snapshot.data ?? 'Loading...';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Comment or Reply
              Text.rich(
                TextSpan(
                  children: [
                    if (repliedToUsername != null)
                      TextSpan(
                        text: '@$repliedToUsername ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    TextSpan(
                      text: comment['text'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "- $username",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Post Details",
          style: TextStyle(
            color: Colors.white,
            // fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<PostModel?>(
        future: _getPostData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Failed to load post details"));
          }

          final post = snapshot.data!;
          final userId = FirebaseAuth.instance.currentUser!.uid;
          final isLiked = post.likes.contains(userId);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.imageUrl != null)
                    Image.network(
                      post.imageUrl!,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  quill.QuillEditor.basic(
                    controller: quill.QuillController(
                      document: quill.Document.fromJson(post.content),
                      selection: const TextSelection.collapsed(offset: 0),
                      readOnly: true,
                    ),
                    configurations: const quill.QuillEditorConfigurations(
                      autoFocus: false,
                      showCursor: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_alt_outlined,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () => toggleLike(post),
                      ),
                      Text('${post.likes.length} upvotes'),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment, color: Colors.grey),
                      Text('  ${post.comments.length} comments'),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    "Comments",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Render comments
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: post.comments.map((comment) {
                      return _buildComment(post, comment);
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Add new comment
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.send, color: Colors.blueAccent),
                          onPressed: () =>
                              addComment(_commentController.text, post),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
