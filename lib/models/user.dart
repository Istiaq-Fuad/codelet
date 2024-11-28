class UserModel {
  String id;
  String email;
  String? photoUrl;
  List<String> interests;
  String role;
  String username;

  UserModel({
    required this.id,
    required this.email,
    this.photoUrl,
    this.interests = const [],
    this.role = '',
    this.username = '',
  });

  // Convert from Firestore document to UserModel instance
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      interests: List<String>.from(data['interests'] ?? []),
      role: data['role'] ?? '',
      username: data['username'] ?? '',
    );
  }

  // Convert UserModel instance to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'photoUrl': photoUrl,
      'interests': interests,
      'role': role,
      'username': username,
    };
  }
}
