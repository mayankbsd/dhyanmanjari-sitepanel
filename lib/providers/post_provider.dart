import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../repositories/admin_repository.dart';
import '../repositories/firebase_admin_repository.dart';

class PostProvider extends ChangeNotifier {
  final AdminRepository _repo = FirebaseAdminRepository();

  List<PostModel> posts = [];

  Future<void> fetchPosts() async {
    posts = await _repo.getPosts();
    notifyListeners();
  }

  Future<void> addPost(String title, String desc) async {
    final post = PostModel(id: '', title: title, description: desc);
    await _repo.addPost(post);
    await fetchPosts();
  }

  Future<void> deletePost(String id) async {
    await _repo.deletePost(id);
    await fetchPosts();
  }
}