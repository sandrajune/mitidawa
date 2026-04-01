import 'package:flutter/material.dart';

import 'blog_detail_screen.dart';

class MyPostsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> posts;

  const MyPostsScreen({
    super.key,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('My Posts'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: posts.isEmpty
          ? const Center(
              child: Text(
                'No published posts yet.',
                style: TextStyle(
                  color: Color(0xFF5A7062),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final post = posts[index];
                final title = (post['title'] as String?)?.trim().isNotEmpty == true
                    ? post['title'] as String
                    : 'Untitled Article';
                final author = (post['author'] as String?)?.trim().isNotEmpty == true
                    ? post['author'] as String
                    : 'Anonymous';
                final createdAtRaw = post['created_at']?.toString();
                final createdAt = DateTime.tryParse(createdAtRaw ?? '')?.toLocal();
                final dateText = createdAt != null
                    ? '${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
                    : 'Unknown date';

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlogDetailScreen(blog: post),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEAECEB)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B4332).withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.article_outlined, color: Color(0xFF1B4332)),
                        const SizedBox(width: 10),
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
                                  color: Color(0xFF162D20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'By $author • $dateText',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5A7062),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF5A7062),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
