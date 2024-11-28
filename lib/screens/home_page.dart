import 'package:codelet/features/auth_service.dart';
import 'package:codelet/models/post.dart';
import 'package:codelet/models/user.dart';
import 'package:codelet/screens/create_post_page.dart';
import 'package:codelet/screens/login_page.dart';
import 'package:codelet/screens/manage_content_page.dart';
import 'package:codelet/screens/user_settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_detail_page.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> _userInterests = [];

  @override
  void initState() {
    super.initState();
    _fetchUserInterests();
  }

  Future<void> _fetchUserInterests() async {
    final interests = await _getUserInterests();
    setState(() {
      _userInterests = interests; // Update the user interests in state
    });
  }

  Future<List<String>> _getUserInterests() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc.data()!, userDoc.id);
          return user.interests;
        }
      } catch (e) {
        print("Error fetching user interests: $e");
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Blog Posts",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.article, color: Colors.blueAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageContentPage()),
                  );
                },
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.blueAccent, // Background color
                  shape: BoxShape.circle,
                ),
                width:
                    60, // Width and height to match the minimum size of the original ElevatedButton
                height: 60,
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  iconSize: 28, // Adjust icon size as needed
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreatePostPage()),
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.blueAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserSettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search blog titles...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('posts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("An error occurred"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No posts available"));
                }

                final posts = snapshot.data!.docs
                    .map((doc) {
                      try {
                        return PostModel.fromFirestore(doc.data(), doc.id);
                      } catch (e) {
                        print("Error converting document ${doc.id}: $e");
                        return null;
                      }
                    })
                    .where((post) => post != null)
                    .where((post) {
                      final title = post!.title;
                      return title
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                    })
                    .toList() // Sort posts by the number of matching interests
                  ..sort((a, b) {
                    final aMatches = a!.categories
                        .where((category) => _userInterests.contains(category))
                        .length;
                    final bMatches = b!.categories
                        .where((category) => _userInterests.contains(category))
                        .length;
                    return bMatches
                        .compareTo(aMatches); // Sort descending by match count
                  });

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PostDetailPage(postId: post.id),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post!.imageUrl != null)
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
                              padding: const EdgeInsets.all(16.0),
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
                                    // post.content,
                                    quill.Document.fromJson(post.content)
                                        .toPlainText(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.thumb_up,
                                            size: 20,
                                            color: Colors.blueAccent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${post.likes.length} upvotes',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.comment,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${post.comments.length} comments',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
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
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
