import 'dart:math';
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'plant_detail_screen.dart';
import 'profile_screen.dart';
import '../widgets/leaf_bubble_card.dart';
import '../widgets/leaf_chatbot_fab.dart';
import '../widgets/leaf_search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _plants = const [
    {'name': 'Neem', 'hint': 'Skin, oral care'},
    {'name': 'Moringa', 'hint': 'Energy, nutrition'},
    {'name': 'Aloe Vera', 'hint': 'Burns, skin soothe'},
    {'name': 'Tulsi', 'hint': 'Cough, cold support'},
    {'name': 'Ginger', 'hint': 'Digestion, nausea'},
    {'name': 'Lemongrass', 'hint': 'Relaxation'},
  ];

  final List<String> _conditions = const [
    'Headache',
    'Cough',
    'Skin Rash',
    'Low Energy',
    'Stomach Pain',
    'Fever',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final filtered = _plants.where((p) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return p['name']!.toLowerCase().contains(q) ||
          p['hint']!.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF7F5EF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LeafSearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            _scanHeroButton(context),
            const SizedBox(height: 18),
            const Text(
              'Plant Catalogue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < filtered.length; i++)
                  LeafBubbleCard(
                    title: filtered[i]['name']!,
                    subtitle: filtered[i]['hint']!,
                    color: [
                      const Color(0xFF66BB6A),
                      const Color(0xFF43A047),
                      const Color(0xFF8BC34A),
                      const Color(0xFFEF6C00),
                    ][i % 4],
                    rotation: (i.isEven ? -1 : 1) * pi / 40,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlantDetailScreen(
                            plantName: filtered[i]['name']!,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Health Conditions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _conditions.map((c) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _query = c;
                      _searchController.text = c;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC80),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Text(
                      c,
                      style: const TextStyle(
                        color: Color(0xFFBF360C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _scanHeroButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 1, end: 1),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => setState(() => _tab = 1),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.spa, color: Colors.white, size: 30),
              SizedBox(width: 12),
              Text(
                'Scan a Leaf for Dawa!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
