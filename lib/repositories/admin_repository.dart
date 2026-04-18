import '../models/post_model.dart';

abstract class AdminRepository {
  Future<List<PostModel>> getPosts();
  Future<void> addPost(PostModel post);
  Future<void> deletePost(String id);
}