import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_page.dart';
import 'create_post_page.dart';
import 'edit_post_page.dart'; // New page for editing posts
import '../models/post.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class ManageContentPage extends StatefulWidget {
  const ManageContentPage({super.key});

  @override
  State<ManageContentPage> createState() => _ManageContentPageState();
}

class _ManageContentPageState extends State<ManageContentPage> {
  String _filterOption = 'All';
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post deleted successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Your Content",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterOption = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'All',
                child: Text('All Posts'),
              ),
              const PopupMenuItem<String>(
                value: 'Popular',
                child: Text('Most Popular'),
              ),
              const PopupMenuItem<String>(
                value: 'Recent',
                child: Text('Most Recent'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No posts found"));
          }

          List<PostModel> posts = snapshot.data!.docs
              .map((doc) => PostModel.fromFirestore(doc.data(), doc.id))
              .toList();

          // Apply filters
          if (_filterOption == 'Popular') {
            posts.sort((a, b) => b.likes.length.compareTo(a.likes.length));
          } else if (_filterOption == 'Recent') {
            posts.sort((a, b) =>
                b.id.compareTo(a.id)); // assuming `id` has a date format
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(postId: post.id),
                    ),
                  );
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.imageUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12.0),
                          ),
                          child: Image.network(
                            post.imageUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              quill.Document.fromJson(post.content)
                                  .toPlainText(),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700]),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.thumb_up,
                                        color: Colors.blueAccent, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post.likes.length} Likes',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.comment,
                                        color: Colors.grey, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post.comments.length} Comments',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueAccent),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditPostPage(
                                          postId: post.id,
                                          title: post.title,
                                          content: post.content,
                                          categories: post.categories,
                                          imageUrl: post.imageUrl,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    _deletePost(post.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.blueAccent,
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const CreatePostPage()),
      //     );
      //   },
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
      backgroundColor: Colors.grey[200],
    );
  }
}
