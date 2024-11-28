import 'package:codelet/features/update_post.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditPostPage extends StatefulWidget {
  final String postId;
  final String title;
  final String? imageUrl;
  final List<String> categories;
  final List<dynamic> content;

  const EditPostPage({
    super.key,
    required this.postId,
    required this.title,
    this.imageUrl,
    required this.categories,
    required this.content,
  });

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late quill.QuillController _contentController;
  late List<String> _selectedCategories;
  File? _image;
  late String postId;

  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _categoryController = TextEditingController();
    _contentController = quill.QuillController(
      document: quill.Document.fromJson(widget.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _selectedCategories = List.from(widget.categories as Iterable);
    postId = widget.postId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        _image = File(imageFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return widget.imageUrl;

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef =
        storageRef.child('posts/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await imageRef.putFile(_image!);
    return await imageRef.getDownloadURL();
  }

  Future<void> _updatePost() async {
    final title = _titleController.text.trim();
    final content = _contentController.document.toDelta().toJson();

    if (title.isEmpty || content.isEmpty || _selectedCategories.isEmpty) return;

    String? imageUrl = await _uploadImage();
    await updatePost(
        postId: postId,
        title: title,
        categories: _selectedCategories,
        content: content,
        imageUrl: imageUrl); // Ensure `updatePost` is defined
    Navigator.pop(context);
  }

  void _addCategory() {
    final category = _categoryController.text.trim();
    if (category.isNotEmpty && !_selectedCategories.contains(category)) {
      setState(() {
        _selectedCategories.add(category);
        _categoryController.clear();
      });
    }
  }

  void _removeCategory(String category) {
    setState(() {
      _selectedCategories.remove(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Post"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!), fit: BoxFit.cover)
                      : (widget.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(widget.imageUrl!),
                              fit: BoxFit.cover)
                          : null),
                ),
                child: (_image == null && widget.imageUrl == null)
                    ? Center(
                        child: Text(
                          "Tap to select an image",
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 16),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: "Add Category",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Colors.blueAccent),
                  onPressed: _addCategory,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: _selectedCategories
                  .map(
                    (category) => Chip(
                      label: Text(category),
                      backgroundColor: Colors.blue[100],
                      deleteIcon: const Icon(Icons.close,
                          size: 18, color: Colors.blueAccent),
                      onDeleted: () => _removeCategory(category),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  quill.QuillToolbar.simple(controller: _contentController),
                  const Divider(height: 1, color: Colors.grey),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(8.0),
                    child: quill.QuillEditor(
                      controller: _contentController,
                      scrollController: _scrollController,
                      focusNode: _focusNode,
                      configurations: const quill.QuillEditorConfigurations(
                        scrollable: true,
                        autoFocus: true,
                        // readOnly: false,
                        expands: false,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updatePost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Update Post",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
