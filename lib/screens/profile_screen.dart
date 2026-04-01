import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'scan_history_screen.dart';
import '../services/wellness_hub_service.dart';
import 'saved_wellness_screen.dart';
import 'my_posts_screen.dart';

// --- Premium Botanical Palette ---
class ProfilePalette {
  static const Color background = Color(0xFFF3F7F4); // Pale sage
  static const Color textPrimary = Color(0xFF162D20); // Deep forest
  static const Color textSecondary = Color(0xFF5A7062);
  static const Color brandGreen = Color(0xFF1B4332);
  static const Color accentGreen = Color(0xFF2D6A4F);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEAECEB);
  static const Color dangerRed = Color(0xFFD32F2F);
  static const Color dangerLight = Color(0xFFFFEBEE);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showDisclaimer = false;
  final WellnessHubService _wellnessHubService = WellnessHubService();
  List<Map<String, dynamic>> _savedPosts = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _myPublishedPosts = const <Map<String, dynamic>>[];
  
  // Settings states (Visual only for this UI, connect to backend if needed)
  bool _notificationsEnabled = true;
  final bool _darkModeEnabled = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String? _avatarUrl;
  bool _isUploading = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSavedPosts();
    _loadMyPublishedPosts();
  }

  Future<void> _loadSavedPosts() async {
    final saved = await _wellnessHubService.getSavedPosts();
    if (!mounted) return;
    setState(() => _savedPosts = saved);
  }

  Future<void> _loadMyPublishedPosts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('wellness_blogs')
          .select()
          .eq('status', 'published')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _myPublishedPosts = List<Map<String, dynamic>>.from(response);
      });
    } catch (_) {
      // Fail silently to avoid breaking profile screen if DB schema differs
      if (!mounted) return;
      setState(() => _myPublishedPosts = const <Map<String, dynamic>>[]);
    }
  }

  // --- Preserved Backend Logic ---
  
  void _loadUserProfile() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = user.userMetadata?['name'] ?? "MitiDawa User";
        _bioController.text = user.userMetadata?['bio'] ?? "";
        _emailController.text = user.email ?? "";
        _avatarUrl = user.userMetadata?['avatar_url'];
      });
    }
  }

  Future<void> _updateProfileMetadata() async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(data: {
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
        }),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: ProfilePalette.accentGreen),
      );
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
  }

  Future<void> _updateEmail() async {
    try {
      final newEmail = _emailController.text.trim();
      if (newEmail.isEmpty || newEmail == supabase.auth.currentUser?.email) return;

      await supabase.auth.updateUser(UserAttributes(email: newEmail));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirmation link sent! Please check your new email inbox.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating email: $e'), backgroundColor: ProfilePalette.dangerRed));
    }
  }

  Future<void> _selectProfilePicture() async {
    try {
      final picker = ImagePicker();
      final imageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (imageFile == null) return;

      setState(() => _isUploading = true);

      final user = supabase.auth.currentUser;
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${user!.id}/profile.$fileExtension';

      await supabase.storage.from('avatars').upload(fileName, File(imageFile.path), fileOptions: const FileOptions(upsert: true));
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      await supabase.auth.updateUser(UserAttributes(data: {'avatar_url': publicUrl}));

      setState(() {
        _avatarUrl = publicUrl;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e'), backgroundColor: ProfilePalette.dangerRed));
    }
  }

  Future<void> _resetPassword() async {
    final email = supabase.auth.currentUser?.email;
    if (email != null) {
      await supabase.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email!'), backgroundColor: ProfilePalette.accentGreen),
      );
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Premium UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfilePalette.background,
      body: Stack(
        children: [
          // Subtle Ambient Background Watermark
          Positioned(
            top: -100,
            left: -50,
            child: Icon(Icons.spa_rounded, size: 400, color: ProfilePalette.brandGreen.withOpacity(0.03)),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                expandedHeight: 80,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: const Text(
                    'Profile',
                    style: TextStyle(
                      color: ProfilePalette.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    children: [
                      _buildIdentityCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      const SizedBox(height: 32),
                      _buildSettingsGroup(),
                      const SizedBox(height: 32),
                      _buildLogoutButton(),
                      const SizedBox(height: 120), // Padding for bottom nav bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. The Identity Card (Apple Contact Style)
  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ProfilePalette.surfaceWhite,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: ProfilePalette.borderLight, width: 1),
        boxShadow: [
          BoxShadow(color: ProfilePalette.brandGreen.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Avatar Stack
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ProfilePalette.accentGreen.withOpacity(0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: ProfilePalette.background,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person_rounded, size: 40, color: ProfilePalette.textSecondary)
                      : null,
                ),
              ),
              if (_isUploading)
                const Positioned.fill(child: CircularProgressIndicator(color: ProfilePalette.brandGreen, strokeWidth: 3)),
              
              // Camera Edit Badge
              GestureDetector(
                onTap: _selectProfilePicture,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ProfilePalette.brandGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: ProfilePalette.surfaceWhite, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Invisible Editable Name Field
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _updateProfileMetadata(),
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ProfilePalette.textPrimary, letterSpacing: -0.5),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: "Enter your name",
              hintStyle: TextStyle(color: ProfilePalette.textSecondary),
            ),
          ),
          
          // Invisible Editable Bio Field
          TextField(
            controller: _bioController,
            textAlign: TextAlign.center,
            maxLines: 2,
            minLines: 1,
            onSubmitted: (_) => _updateProfileMetadata(),
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 15, color: ProfilePalette.textSecondary, height: 1.4),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: "Add a bio about your natural remedy journey...",
              hintStyle: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ProfilePalette.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _emailController.text.isEmpty ? "No Email" : _emailController.text,
              style: const TextStyle(fontSize: 13, color: ProfilePalette.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Quick Actions
  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                title: 'Saved',
                icon: Icons.bookmark_rounded,
                color: const Color(0xFF8B7355), // Earthy brown
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SavedWellnessScreen(savedPosts: _savedPosts),
                    ),
                  ).then((_) {
                    _loadSavedPosts();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionButton(
                title: 'History',
                icon: Icons.history_rounded,
                color: ProfilePalette.accentGreen,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PostsQuickActionButton(
          posts: _myPublishedPosts,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyPostsScreen(posts: _myPublishedPosts),
              ),
            ).then((_) {
              _loadMyPublishedPosts();
            });
          },
        ),
      ],
    );
  }

  // 3. Apple-Style Settings Group
  Widget _buildSettingsGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'ACCOUNT & PREFERENCES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ProfilePalette.textSecondary, letterSpacing: 1.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ProfilePalette.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ProfilePalette.borderLight, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  activeColor: ProfilePalette.brandGreen,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
              ),
              _buildDivider(),
              _SettingsTile(
                icon: Icons.lock_reset_rounded,
                title: 'Reset Password',
                onTap: _resetPassword,
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ProfilePalette.borderLight),
              ),
              _buildDivider(),
              _SettingsTile(
                icon: Icons.shield_rounded,
                title: 'Medical Disclaimer',
                onTap: () => setState(() => _showDisclaimer = !_showDisclaimer),
                trailing: Icon(_showDisclaimer ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: ProfilePalette.textSecondary),
              ),
              // Animated Disclaimer Dropdown
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ProfilePalette.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ProfilePalette.brandGreen.withOpacity(0.1)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: ProfilePalette.brandGreen, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Always consult a certified medical professional. Natural remedies are for holistic support and are not a replacement for medical advice or prescribed treatments.',
                            style: TextStyle(fontSize: 13, color: ProfilePalette.textSecondary, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                crossFadeState: _showDisclaimer ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Elegant Destructive Action
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: ProfilePalette.dangerLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ProfilePalette.dangerRed.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: ProfilePalette.dangerRed, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(color: ProfilePalette.dangerRed, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: ProfilePalette.borderLight, indent: 56);
  }
}

// --- Reusable UI Components ---

class _QuickActionButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: ProfilePalette.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ProfilePalette.borderLight, width: 1),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ProfilePalette.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostsQuickActionButton extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final VoidCallback onTap;

  const _PostsQuickActionButton({
    required this.posts,
    required this.onTap,
  });

  @override
  State<_PostsQuickActionButton> createState() => _PostsQuickActionButtonState();
}

class _PostsQuickActionButtonState extends State<_PostsQuickActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.posts.length;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: ProfilePalette.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ProfilePalette.borderLight),
            boxShadow: [
              BoxShadow(
                color: ProfilePalette.brandGreen.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ProfilePalette.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article_rounded, color: ProfilePalette.brandGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Posts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ProfilePalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0 ? 'No published posts yet' : '$count published posts',
                      style: const TextStyle(
                        fontSize: 13,
                        color: ProfilePalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: ProfilePalette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: ProfilePalette.background, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: ProfilePalette.brandGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ProfilePalette.textPrimary),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}