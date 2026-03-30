import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';
import 'plant_catalogue_screen.dart';
import 'health_conditions_screen.dart';
import '../widgets/leaf_chatbot_fab.dart';

class AppColors {
  static const Color creamBackground =
      Color.fromARGB(255, 243, 243, 239); // example color
  static const Color botanicalGreen = Color(0xFF4CAF50); // example color
  static const Color deepMossGreen = Color(0xFF2E7D32); // example color
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
      _buildHome(context),
      const CameraScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_tab],
      floatingActionButton: _tab == 0 ? const LeafChatbotFab() : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 249, 249, 246),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Centered Header
            children: [
              // Centered Header with Vine Styling
              const Icon(Icons.eco_outlined,
                  color: AppColors.botanicalGreen, size: 32),
              const SizedBox(height: 8),
              const Text(
                'Welcome to MitiDawa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: 'Lora', // Use a font like 'Lora' or 'Playfair'
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 18, 54, 45),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose where you want to start',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: Colors.black54),
              ),

              // INCREASED SPACING HERE
              const SizedBox(height: 32),

              _homeActionCard(
                title: 'Plant Catalogue',
                subtitle: 'Browse medicinal plants and get therapeutic usages',
                icon: Icons.spa,
                accent: const Color.fromARGB(255, 18, 54, 45),
                isDark: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlantCatalogueScreen(),
                    ),
                  );
                },
              ),

              // INCREASED SPACING HERE
              const SizedBox(height: 48),

              _homeActionCard(
                title: 'Health Conditions',
                subtitle: 'Find plants by symptoms and common ailments',
                icon: Icons.health_and_safety,
                accent: const Color.fromARGB(255, 91, 45, 23),
                isDark: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HealthConditionsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // INCREASED HEIGHT HERE (from 160 to 220)
        height: 220,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? accent.withOpacity(0.85) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? Colors.transparent : accent.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.1),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background "Vine" Decorative Icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.spa_outlined,
                size: 140, // INCREASED ICON SIZE (from 100 to 140)
                color: (isDark ? Colors.white : accent).withOpacity(0.1),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28, // INCREASED FONT SIZE (from 24 to 28)
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : accent,
                  ),
                ),
                const SizedBox(
                    height:
                        8), // Slightly bigger gap between title and subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16, // INCREASED FONT SIZE (from 14 to 16)
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.3, // Added line height for better readability
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
