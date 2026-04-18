import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'admin_repository.dart';

class FirebaseAdminRepository implements AdminRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Future<List<PostModel>> getPosts() async {
    final snapshot = await _db.collection('posts').get();
    return snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addPost(PostModel post) async {
    await _db.collection('posts').add(post.toMap());
  }

  @override
  Future<void> deletePost(String id) async {
    await _db.collection('posts').doc(id).delete();
  }
}