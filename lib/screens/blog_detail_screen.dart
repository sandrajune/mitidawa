import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/wellness_hub_service.dart';

class BlogDetailScreen extends StatefulWidget {
  final Map<String, dynamic> blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final WellnessHubService _wellnessHubService = WellnessHubService();
  final TextEditingController _commentController = TextEditingController();

  bool _isSaved = false;
  bool _isSaving = false;
  bool _isPostingComment = false;
  List<Map<String, dynamic>> _comments = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadSavedAndComments();
  }

  Future<void> _loadSavedAndComments() async {
    final saved = await _wellnessHubService.isPostSaved(widget.blog);
    final comments = await _wellnessHubService.getCommentsForPost(widget.blog);
    if (!mounted) return;
    setState(() {
      _isSaved = saved;
      _comments = comments;
    });
  }

  Future<void> _toggleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      if (_isSaved) {
        await _wellnessHubService.removeSavedPost(widget.blog);
      } else {
        await _wellnessHubService.savePost(widget.blog);
      }
      if (!mounted) return;
      setState(() => _isSaved = !_isSaved);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Article saved to profile.' : 'Article removed from saved list.'),
          backgroundColor: const Color(0xFF2D6A4F),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _postComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _isPostingComment) return;

    setState(() => _isPostingComment = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final metadataName = user?.userMetadata?['name']?.toString().trim();
      final email = user?.email?.trim();

      var commenter = 'Community Member';
      if (metadataName != null && metadataName.isNotEmpty) {
        commenter = metadataName;
      } else if (email != null && email.isNotEmpty) {
        commenter = email.split('@').first;
      }

      await _wellnessHubService.addComment(
        blog: widget.blog,
        comment: comment,
        commenter: commenter,
      );
      _commentController.clear();
      await _loadSavedAndComments();
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.blog['title'] as String?)?.trim().isNotEmpty == true
        ? widget.blog['title'] as String
        : 'Untitled Article';
    final author = (widget.blog['author'] as String?)?.trim().isNotEmpty == true
        ? widget.blog['author'] as String
        : 'Anonymous';
    final content = (widget.blog['content'] as String?)?.trim().isNotEmpty == true
        ? widget.blog['content'] as String
        : 'No content available.';
    final createdAtRaw = widget.blog['created_at']?.toString();
    final createdAt = DateTime.tryParse(createdAtRaw ?? '')?.toLocal();

    final imageUrls = _extractImageUrls(widget.blog);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: const Text('Wellness Hub'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // Pass the current save state back to the previous screen
            Navigator.pop(context, _isSaved);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'By $author${createdAt != null ? ' • ${_formatDate(createdAt)}' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A7062),
                  ),
                ),
                if (imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      itemBuilder: (_, index) {
                        final url = imageUrls[index];
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFFF1F8F3),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined, color: Color(0xFF5A7062)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _toggleSave,
                        icon: Icon(
                          _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: const Color(0xFF1B4332),
                        ),
                        label: Text(
                          _isSaved ? 'Saved' : 'Save',
                          style: const TextStyle(
                            color: Color(0xFF1B4332),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF2D6A4F).withOpacity(0.35)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    filled: true,
                    fillColor: const Color(0xFFF1F8F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF2D6A4F).withOpacity(0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF2D6A4F).withOpacity(0.15)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isPostingComment ? null : _postComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post Comment'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_comments.isEmpty)
                  const Text(
                    'No comments yet. Start the conversation.',
                    style: TextStyle(color: Color(0xFF5A7062), fontWeight: FontWeight.w500),
                  )
                else
                  ..._comments.map(
                    (comment) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FBF8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (comment['commenter'] as String?) ?? 'Community Member',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (comment['comment'] as String?) ?? '',
                            style: const TextStyle(
                              color: Color(0xFF355244),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _extractImageUrls(Map<String, dynamic> blog) {
    final urls = <String>[];

    final direct = blog['image_url'];
    if (direct is String && direct.trim().isNotEmpty) {
      urls.add(direct.trim());
    }

    final rawList = blog['image_urls'];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is String && item.trim().isNotEmpty) {
          urls.add(item.trim());
        }
      }
    }

    return urls;
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
