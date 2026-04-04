import 'package:flutter/material.dart';
import 'dart:ui';
import 'camera_screen.dart';
import 'profile_screen.dart';
import 'plant_catalogue_screen.dart';
import 'health_conditions_screen.dart';
import '../widgets/leaf_chatbot_fab.dart';

// --- Minimalist Nature Palette ---
class AppColors {
  static const Color background = Color(0xFFFCFCFA); // Warmer, earthy off-white
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color brandGreen = Color(0xFF234B35); // Rich forest green
  static const Color brandGreenLight = Color(0xFFE8F1EC); // Soft minty background
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEAECEB); // Slightly green-tinted gray
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _NatureMinimalistHomeView(),
      const CameraScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, 
      body: screens[_tab],
      floatingActionButton: _tab == 0 
          ? const Padding(
              padding: EdgeInsets.only(bottom: 80.0), 
              child: LeafChatbotFab(),
            )
          : null,
      // FIX: Removed 'const' and properly passed the state down
      bottomNavigationBar: _AppleGlassNavBar(
        selectedIndex: _tab,
        onTabSelected: (index) {
          setState(() {
            _tab = index;
          });
        },
      ),
    );
  }
}

// --- The Nature-Infused Minimalist Home View ---
class _NatureMinimalistHomeView extends StatelessWidget {
  const _NatureMinimalistHomeView();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.15 : 24.0;

    return Stack(
      children: [
        // 1. The Canopy Effect (Ambient Background Nature)
        Positioned(
          top: -120,
          right: -80,
          child: IgnorePointer(
            child: Icon(
              Icons.energy_savings_leaf_rounded,
              size: 400,
              color: AppColors.brandGreen.withOpacity(0.03),
            ),
          ),
        ),

        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Minimal Brand Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.brandGreenLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.spa_rounded, color: AppColors.brandGreen, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'MitiDawa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppColors.brandGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      
                      // 2. Earthy Typography
                      const Text(
                        'Discover\nNatural Healing',
                        style: TextStyle(
                          fontSize: 38,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          color: AppColors.brandGreen, // Anchors the design in green
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Explore the world of botanical medicine and natural remedies.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Action Cards
                      _CleanActionCard(
                        title: 'Plant Catalogue',
                        subtitle: 'Browse medicinal botanical species',
                        icon: Icons.energy_savings_leaf_outlined,
                        accentColor: AppColors.brandGreen,
                        watermarkIcon: Icons.grass_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlantCatalogueScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _CleanActionCard(
                        title: 'Health Conditions',
                        subtitle: 'Find remedies by symptoms',
                        icon: Icons.monitor_heart_outlined,
                        accentColor: const Color(0xFF8B7355), // Soft earthy clay
                        watermarkIcon: Icons.local_florist_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HealthConditionsScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- The Minimal Action Card with Nature Watermarks ---
class _CleanActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final IconData watermarkIcon;
  final VoidCallback onTap;

  const _CleanActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.watermarkIcon,
    required this.onTap,
  });

  @override
  State<_CleanActionCard> createState() => _CleanActionCardState();
}

class _CleanActionCardState extends State<_CleanActionCard> {
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
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.04), // Faint colored shadow
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // 3. Card Watermark
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    widget.watermarkIcon,
                    size: 140,
                    color: widget.accentColor.withOpacity(0.04),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(widget.icon, color: widget.accentColor, size: 28),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.textSecondary.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- iOS Style Frosted Glass Bottom Nav ---
// FIX: Converted to properly accept variables instead of looking up the tree
class _AppleGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _AppleGlassNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: AppColors.borderLight.withOpacity(0.6),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavButton(
                    icon: Icons.home_filled,
                    outlineIcon: Icons.home_outlined,
                    isSelected: selectedIndex == 0,
                    onTap: () => onTabSelected(0),
                  ),
                  _NavButton(
                    icon: Icons.document_scanner_rounded,
                    outlineIcon: Icons.document_scanner_outlined,
                    isSelected: selectedIndex == 1,
                    onTap: () => onTabSelected(1),
                  ),
                  _NavButton(
                    icon: Icons.person_rounded,
                    outlineIcon: Icons.person_outline_rounded,
                    isSelected: selectedIndex == 2,
                    onTap: () => onTabSelected(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData outlineIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.outlineIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandGreenLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isSelected ? icon : outlineIcon,
          size: 26,
          color: isSelected ? AppColors.brandGreen : AppColors.textSecondary,
        ),
      ),
    );
  }
}