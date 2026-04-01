import 'package:flutter/material.dart';
import 'package:mitidawa/screens/blog_detail_screen.dart';
import 'package:mitidawa/screens/profile_screen.dart';
// Note: Ensure you have imported BlogDetailScreen and ProfilePalette 
// to match your project's directory structure.

class SavedWellnessScreen extends StatefulWidget {
  final List<dynamic> savedPosts;

  const SavedWellnessScreen({
    super.key, 
    required this.savedPosts,
  });

  @override
  State<SavedWellnessScreen> createState() => _SavedWellnessScreenState();
}

class _SavedWellnessScreenState extends State<SavedWellnessScreen> {
  late List<dynamic> _posts;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the list so we can remove items dynamically
    _posts = List.from(widget.savedPosts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfilePalette.background,
      appBar: AppBar(
        backgroundColor: ProfilePalette.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: ProfilePalette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Wellness Posts',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ProfilePalette.textPrimary,
          ),
        ),
      ),
      body: _posts.isEmpty
          ? const Center(
              child: Text(
                'No saved wellness posts yet.',
                style: TextStyle(
                  color: ProfilePalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                final title = (post['title'] as String?)?.trim().isNotEmpty == true
                    ? post['title'] as String
                    : 'Untitled Article';
                final author = (post['author'] as String?)?.trim().isNotEmpty == true
                    ? post['author'] as String
                    : 'Anonymous';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      // Wait for the boolean return value from BlogDetailScreen
                      final isStillSaved = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlogDetailScreen(blog: post),
                        ),
                      );

                      // If the user tapped 'Saved' to unsave the post, remove it from the UI instantly
                      if (isStillSaved == false) {
                        setState(() {
                          _posts.removeAt(index);
                        });
                      }
                    },
                    child: Ink(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ProfilePalette.surfaceWhite, 
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: ProfilePalette.accentGreen.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: ProfilePalette.accentGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bookmark_rounded,
                              color: ProfilePalette.brandGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: ProfilePalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By $author',
                                  style: const TextStyle(
                                    color: ProfilePalette.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: ProfilePalette.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}