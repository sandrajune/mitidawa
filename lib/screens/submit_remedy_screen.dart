import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmitRemedyScreen extends StatefulWidget {
  const SubmitRemedyScreen({super.key});

  @override
  State<SubmitRemedyScreen> createState() => _SubmitRemedyScreenState();
}

class _SubmitRemedyScreenState extends State<SubmitRemedyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = user?.userMetadata?['name']?.toString().trim();
    final email = user?.email?.trim();

    if (metadataName != null && metadataName.isNotEmpty) {
      _authorController.text = metadataName;
    } else if (email != null && email.isNotEmpty) {
      _authorController.text = email.split('@').first;
    }
  }

  Future<void> submitUserBlog(String title, String author, String content) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('wellness_blogs').insert({
        'title': title,
        'author': author,
        'content': content,
        'status': 'pending',
        'user_id': currentUserId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your post has been submitted for review.'),
          backgroundColor: Color(0xFF2D6A4F),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      rethrow;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await submitUserBlog(
        _titleController.text.trim(),
        _authorController.text.trim(),
        _contentController.text.trim(),
      );

      if (!mounted) return;
      _formKey.currentState?.reset();
      _titleController.clear();
      _authorController.clear();
      _contentController.clear();
      Navigator.of(context).pop();
    } catch (_) {
      // Error feedback already shown in submitUserBlog
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: const Text('Wellness Blog'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.2)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share your natural plant remedy with the community',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Title'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _authorController,
                    decoration: _inputDecoration('Author Name'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Please enter the author name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentController,
                    minLines: 8,
                    maxLines: 12,
                    decoration: _inputDecoration('Content'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Please enter content' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
    );
  }
}
