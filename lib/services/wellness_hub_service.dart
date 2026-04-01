import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WellnessHubService {
  static const String _savedPostsKey = 'saved_wellness_posts';
  static const String _commentsKeyPrefix = 'wellness_comments_';

  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedPostsKey) ?? <String>[];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList(growable: false);
  }

  Future<bool> isPostSaved(Map<String, dynamic> blog) async {
    final saved = await getSavedPosts();
    final targetId = _blogId(blog);
    if (targetId == null) return false;
    return saved.any((item) => _blogId(item) == targetId);
  }

  Future<void> savePost(Map<String, dynamic> blog) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await getSavedPosts().then((value) => value.toList());

    final targetId = _blogId(blog);
    if (targetId == null) return;

    final exists = saved.any((item) => _blogId(item) == targetId);
    if (!exists) {
      saved.add(blog);
      final encoded = saved.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList(_savedPostsKey, encoded);
    }
  }

  Future<void> removeSavedPost(Map<String, dynamic> blog) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await getSavedPosts().then((value) => value.toList());

    final targetId = _blogId(blog);
    if (targetId == null) return;

    saved.removeWhere((item) => _blogId(item) == targetId);
    final encoded = saved.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_savedPostsKey, encoded);
  }

  Future<List<Map<String, dynamic>>> getCommentsForPost(Map<String, dynamic> blog) async {
    final prefs = await SharedPreferences.getInstance();
    final id = _blogId(blog);
    if (id == null) return <Map<String, dynamic>>[];

    final raw = prefs.getStringList('$_commentsKeyPrefix$id') ?? <String>[];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList(growable: false);
  }

  Future<void> addComment({
    required Map<String, dynamic> blog,
    required String comment,
    String commenter = 'Community Member',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = _blogId(blog);
    if (id == null) return;

    final comments = await getCommentsForPost(blog).then((value) => value.toList());
    comments.add({
      'comment': comment,
      'commenter': commenter,
      'created_at': DateTime.now().toIso8601String(),
    });

    final encoded = comments.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('$_commentsKeyPrefix$id', encoded);
  }

  String? _blogId(Map<String, dynamic> blog) {
    final id = blog['id'];
    if (id == null) return null;
    return id.toString();
  }
}
