import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'scan_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showDisclaimer = false;
  final bool _notificationsEnabled = true;
  final bool _darkModeEnabled = false;
  final String _language = 'English';

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
  }

  // 1. Load data from Supabase Auth Metadata
  void _loadUserProfile() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = user.userMetadata?['name'] ?? "Miti Dawa User";
        _bioController.text = user.userMetadata?['bio'] ?? "";
        _emailController.text = user.email ?? "";
        _avatarUrl = user.userMetadata?['avatar_url'];
      });
    }
  }

  // 2. Save Name & Bio to Supabase Metadata
  Future<void> _updateProfileMetadata() async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(data: {
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
        }),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
  }

  // 3. Update Email Address
  Future<void> _updateEmail() async {
    try {
      final newEmail = _emailController.text.trim();
      if (newEmail.isEmpty || newEmail == supabase.auth.currentUser?.email) {
        return;
      }

      await supabase.auth.updateUser(UserAttributes(email: newEmail));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Confirmation link sent! Please check your new email inbox to verify the change.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating email: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // 4. Upload Photo to Supabase Storage
  Future<void> _selectProfilePicture() async {
    try {
      final picker = ImagePicker();
      final imageFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (imageFile == null) return;

      setState(() => _isUploading = true);

      final user = supabase.auth.currentUser;
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${user!.id}/profile.$fileExtension';

      await supabase.storage.from('avatars').upload(
            fileName,
            File(imageFile.path),
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      await supabase.auth
          .updateUser(UserAttributes(data: {'avatar_url': publicUrl}));

      setState(() {
        _avatarUrl = publicUrl;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // 5. Send Password Reset Email
  Future<void> _resetPassword() async {
    final email = supabase.auth.currentUser?.email;
    if (email != null) {
      await supabase.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: Colors.green),
      );
    }
  }

  // 6. Logout
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

  @override
  Widget build(BuildContext context) {
    const creamBackground = Color(0xFFF4FBF8);
    const darkBrown = Color.fromARGB(255, 243, 184, 157);
    const deepGreen = Color.fromARGB(255, 18, 54, 45);
    const bubbleGreen = Color.fromARGB(174, 132, 195, 149);
    const bubbleOrange = Color.fromARGB(255, 217, 148, 117);

    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: Text('Profile',
            style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w800)),
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        // Removed logout icon from here!
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Profile Picture ---
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: bubbleGreen.withValues(alpha: 0.35),
                  backgroundImage:
                      _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                if (_isUploading)
                  const Positioned.fill(
                      child: CircularProgressIndicator(color: deepGreen)),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _selectProfilePicture,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: darkBrown,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4)
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // --- Editable Name ---
            SizedBox(
              width: 280,
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                onSubmitted: (_) => _updateProfileMetadata(),
                style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: deepGreen),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter your name",
                  hintStyle: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w300,
                      color: deepGreen.withValues(alpha: 0.5)),
                ),
              ),
            ),

            // --- Editable Bio ---
            SizedBox(
              width: 280,
              child: TextField(
                controller: _bioController,
                textAlign: TextAlign.center,
                maxLines: 2,
                onSubmitted: (_) => _updateProfileMetadata(),
                style: GoogleFonts.nunitoSans(
                    fontSize: 16, color: const Color.fromARGB(255, 32, 30, 29)),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Add a bio about your natural remedy journey...",
                  hintStyle: GoogleFonts.nunitoSans(
                      fontStyle: FontStyle.italic,
                      color: const Color.fromARGB(255, 27, 26, 26)
                          .withValues(alpha: 0.5)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 28),

            _tile(
              'Saved Remedies',
              Icons.bookmark,
              deepGreen,
              bubbleGreen,
            ),
            _tile(
              'Scan History',
              Icons.history,
              deepGreen,
              bubbleGreen,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScanHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            _settingsCard(darkBrown, deepGreen),
            const SizedBox(height: 32),

            GestureDetector(
              onTap: () => setState(() => _showDisclaimer = !_showDisclaimer),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: deepGreen,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disclaimer',
                        style: GoogleFonts.nunitoSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    if (_showDisclaimer) ...[
                      const SizedBox(height: 12),
                      Text(
                          'Always consult a doctor. Natural remedies are not a replacement for medical advice.',
                          style: GoogleFonts.nunitoSans(color: Colors.white70)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Logout Button (Moved here!) ---
            _tile(
                'Logout',
                Icons.logout,
                Colors
                    .red, // Making it red to stand out as a destructive action
                bubbleOrange.withValues(alpha: 0.3),
                onTap: _logout),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(Color darkBrown, Color deepGreen) {
    // Note: I left this empty just to keep the code block shorter,
    // simply paste your existing _settingsCard logic exactly as it was here!
    return Container();
  }

  Widget _tile(String label, IconData icon, Color iconColor, Color bgColor,
      {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: iconColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(label,
            style: GoogleFonts.montserrat(
                color: iconColor, fontWeight: FontWeight.w600, fontSize: 17)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 18, color: iconColor.withValues(alpha: 0.7)),
        onTap: onTap,
      ),
    );
  }
}
