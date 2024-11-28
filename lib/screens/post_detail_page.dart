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
  final TextEditingController _replyController = TextEditingController();
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

  // Fetch and cache usernames from Firestore
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
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
      'replies': [],
    };
    setState(() {
      post.comments.add(newComment);
    });

    await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
      'comments': post.comments,
    });

    _commentController.clear();
  }

  Future<void> addReply(
      String text, Map<String, dynamic> comment, PostModel post) async {
    final reply = {
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    setState(() {
      comment['replies'].add(reply);
      replyingToCommentId = null;
    });

    await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
      'comments': post.comments,
    });

    _replyController.clear();
  }

  Widget _buildComment(PostModel post, Map<String, dynamic> comment) {
    final isReplying = replyingToCommentId == comment['userId'];

    return FutureBuilder<String>(
      future: _getUsername(comment['userId']),
      builder: (context, snapshot) {
        final username = snapshot.data ?? 'Loading...';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment Box
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // Shadow position
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username and Comment Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            replyingToCommentId = comment['userId'];
                          });
                        },
                        child: const Text(
                          'Reply',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment['text'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Display Replies
            if (comment['replies'] != null && comment['replies'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  children: comment['replies'].map<Widget>((reply) {
                    return FutureBuilder<String>(
                      future: _getUsername(reply['userId']),
                      builder: (context, replySnapshot) {
                        final replyUsername =
                            replySnapshot.data ?? 'Loading...';

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replyUsername,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply['text'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),

            // Add Reply TextField if Replying
            if (isReplying)
              Padding(
                padding: const EdgeInsets.only(left: 24.0, top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: 'Write a reply...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 10.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: () {
                        addReply(_replyController.text, comment, post);
                        _replyController
                            .clear(); // Clear the field after sending
                      },
                    ),
                  ],
                ),
              ),
            const Divider(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Details"),
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
                      Text('${post.comments.length} comments'),
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
                    children: post.comments
                        .map((comment) => _buildComment(post, comment))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  // Add new comment
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                              hintText: 'Write a comment...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () =>
                            addComment(_commentController.text, post),
                      ),
                    ],
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
