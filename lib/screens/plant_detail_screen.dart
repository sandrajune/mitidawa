import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../models/plant.dart';

// --- Lush Botanical Palette ---
class DetailPalette {
  static const Color background = Color(0xFFF0F4F1); // Slightly richer sage
  static const Color textPrimary = Color(0xFF162D20); // Deepest forest
  static const Color textSecondary = Color(0xFF5A7062);
  static const Color brandGreen = Color(0xFF1B4332);
  static const Color accentGreen = Color(0xFF2D6A4F); // Vibrant leaf green
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color chipBackground = Color(0xFFE2EBE5);
}

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final imageUrls = <String>[
      widget.plant.primaryImageUrl.trim(),
      widget.plant.detailImageUrl.trim(),
    ].where((url) => url.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: DetailPalette.background,
      body: Stack(
        children: [
          // 1. Ambient Background Watermark
          Positioned(
            top: 200,
            right: -120,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Icon(
                Icons.energy_savings_leaf_rounded,
                size: 500,
                color: DetailPalette.brandGreen.withOpacity(0.02),
              ),
            ),
          ),

          // 2. Animated Floating Leaves (Adds Life!)
          const Positioned(top: 300, left: -20, child: _FloatingLeaf(size: 80, delay: 0)),
          const Positioned(top: 600, right: -10, child: _FloatingLeaf(size: 120, delay: 1500)),

          // 3. Main Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Immersive Header
              SliverAppBar(
                expandedHeight: 420,
                stretch: true,
                pinned: true,
                backgroundColor: DetailPalette.background,
                surfaceTintColor: Colors.transparent,
                leading: _buildFrostedBackButton(context),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: _buildImageCarousel(imageUrls),
                ),
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: DetailPalette.background.withOpacity(0.9), // Slightly transparent to see leaves
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DetailPalette.brandGreen.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ]
                  ),
                  transform: Matrix4.translationValues(0.0, -40.0, 0.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 36, 24, 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plant Name & Scientific Name
                            Text(
                              widget.plant.name,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: DetailPalette.textPrimary,
                                letterSpacing: -1.0,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.eco_rounded, color: DetailPalette.accentGreen, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.plant.scientificName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      color: DetailPalette.accentGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 36),

                            // FIXED HIERARCHY: Description -> Uses -> Local Names
                            _buildEditorialCard(
                              title: 'Description',
                              icon: Icons.auto_awesome_outlined,
                              watermark: Icons.grass_rounded,
                              contentWidget: Text(
                                widget.plant.description.isEmpty ? 'No description available.' : widget.plant.description,
                                style: const TextStyle(fontSize: 16, color: DetailPalette.textSecondary, height: 1.6),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            _buildUsesSection(widget.plant.uses),

                            const SizedBox(height: 20),
                            _buildLocalNamesSection(widget.plant.localNames),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI Builders ---

  Widget _buildFrostedBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: DetailPalette.brandGreen.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        color: DetailPalette.brandGreen,
        child: const Center(child: Icon(Icons.local_florist_rounded, size: 80, color: Colors.white24)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: imageUrls.length,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemBuilder: (context, index) {
            return Image.network(
              imageUrls[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator(color: DetailPalette.brandGreen));
              },
            );
          },
        ),
        
        // Dark gradient to make white back button pop and blend into the content
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4), // Darker at top for back button
                  Colors.transparent,
                  Colors.transparent,
                  DetailPalette.background, // Blends perfectly into the rounded content box
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),
        ),

        if (imageUrls.length > 1)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index ? DetailPalette.accentGreen : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditorialCard({
    required String title, 
    required IconData icon, 
    required IconData watermark, 
    required Widget contentWidget
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DetailPalette.surfaceWhite.withOpacity(0.85),
        borderRadius: BorderRadius.circular(32),
        // Soft gradient border giving a premium glassy feel
        border: Border.all(color: DetailPalette.brandGreen.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: DetailPalette.brandGreen.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtly blended nature watermark inside the card
          Positioned(
            right: -20,
            top: -10,
            child: Icon(watermark, size: 100, color: DetailPalette.brandGreen.withOpacity(0.03)),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DetailPalette.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: DetailPalette.accentGreen, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: DetailPalette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              contentWidget,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsesSection(String uses) {
    final useLines = _normalizeListText(uses);
    if (useLines.isEmpty) return const SizedBox.shrink();

    return _buildEditorialCard(
      title: 'Therapeutic Uses',
      icon: Icons.monitor_heart_outlined,
      watermark: Icons.local_florist_rounded,
      contentWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: useLines.map((line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: DetailPalette.accentGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: DetailPalette.accentGreen, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: DetailPalette.textSecondary, fontSize: 16, height: 1.5),
                      children: _parseUseLine(line),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocalNamesSection(String localNames) {
    final names = _normalizeListText(localNames);
    if (names.isEmpty) return const SizedBox.shrink();

    return _buildEditorialCard(
      title: 'Local Names',
      icon: Icons.language_rounded,
      watermark: Icons.map_rounded,
      contentWidget: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: names.map((name) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: DetailPalette.chipBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DetailPalette.brandGreen.withOpacity(0.05)),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: DetailPalette.brandGreen,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Preserved Parsing Logic ---
  List<String> _normalizeListText(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return [];
    if (raw.contains('{') && raw.contains('}')) {
      final matches = RegExp(r'\{([^}]+)\}').allMatches(raw);
      if (matches.isNotEmpty) return matches.map((m) => m.group(1)!.trim()).toList();
    }
    return raw.replaceAll('[', '').replaceAll(']', '').split(RegExp(r'[,\n\r]+'))
        .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
        .where((e) => e.isNotEmpty).toList();
  }

  List<TextSpan> _parseUseLine(String line) {
    String lowerLine = line.toLowerCase();
    if (lowerLine.contains('category:') && lowerLine.contains('description:')) {
      final catMatch = RegExp(r'category:\s*([^,]+)', caseSensitive: false).firstMatch(line);
      final descMatch = RegExp(r'description:\s*(.+)', caseSensitive: false).firstMatch(line);
      return [
        TextSpan(text: catMatch != null ? catMatch.group(1)!.trim() : 'Use', style: const TextStyle(fontWeight: FontWeight.w800, color: DetailPalette.textPrimary)),
        const TextSpan(text: ' — '),
        TextSpan(text: descMatch != null ? descMatch.group(1)!.trim() : line),
      ];
    }
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) return [TextSpan(text: line.replaceFirst(RegExp(r'^[\d\.\-\*\)]+\s*'), ''))];
    return [
      TextSpan(text: line.substring(0, colonIndex).replaceFirst(RegExp(r'^[\d\.\-\*\)]+\s*'), '').trim(), style: const TextStyle(fontWeight: FontWeight.w800, color: DetailPalette.textPrimary)),
      const TextSpan(text: ' — '),
      TextSpan(text: line.substring(colonIndex + 1).trim()),
    ];
  }
}

// --- Custom Animated Floating Leaf Widget ---
class _FloatingLeaf extends StatefulWidget {
  final double size;
  final int delay;

  const _FloatingLeaf({required this.size, required this.delay});

  @override
  State<_FloatingLeaf> createState() => _FloatingLeafState();
}

class _FloatingLeafState extends State<_FloatingLeaf> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Stagger the animations so they don't move exactly together
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          // Gently bob up and down
          offset: Offset(0, math.sin(_controller.value * math.pi * 2) * 20),
          child: Transform.rotate(
            // Gently rock back and forth
            angle: math.cos(_controller.value * math.pi) * 0.1,
            child: Icon(
              Icons.spa_rounded,
              size: widget.size,
              color: DetailPalette.accentGreen.withOpacity(0.04),
            ),
          ),
        );
      },
    );
  }
}