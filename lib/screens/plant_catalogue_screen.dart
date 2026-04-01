import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../models/plant.dart';
import '../services/plant_service.dart';
import 'plant_detail_screen.dart';

// --- Greener, Lush Minimalist Palette ---
class CataloguePalette {
  static const Color background = Color(0xFFF3F7F4); // Pale sage background
  static const Color textPrimary = Color(0xFF1A3324); // Deep forest text
  static const Color textSecondary = Color(0xFF6B8074); // Green-tinted gray
  static const Color brandGreen = Color(0xFF1E4D3B);
  static const Color searchBackground = Color(0xFFE6EFE9); // Soft minty search bar
  
  // Dynamic Card Backgrounds to make the grid feel like a garden
  static const List<Color> botanicalTints = [
    Color(0xFFE8F1EC), // Soft Mint
    Color(0xFFEBF2E3), // Spring Green
    Color(0xFFF2EFE8), // Warm Oat
    Color(0xFFE2EBE5), // Cool Sage
  ];
}

class PlantCatalogueScreen extends StatefulWidget {
  const PlantCatalogueScreen({super.key});

  @override
  State<PlantCatalogueScreen> createState() => _PlantCatalogueScreenState();
}

class _PlantCatalogueScreenState extends State<PlantCatalogueScreen> {
  final PlantService _plantService = PlantService();
  final TextEditingController _searchController = TextEditingController();

  List<Plant> _plants = [];
  bool _isLoading = true;
  String _query = '';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final plants = await _plantService.fetchPlants();
    if (!mounted) return;
    setState(() {
      _plants = plants;
      _loadError = plants.isEmpty ? _plantService.lastFetchError : null;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _plants.where((p) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.hint.toLowerCase().contains(q) ||
          p.scientificName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: CataloguePalette.background,
      body: Stack(
        children: [
          // Subtle Ambient Leaf Overlay for the whole screen
          Positioned(
            top: -50,
            right: -100,
            child: Icon(
              Icons.spa_rounded,
              size: 350,
              color: CataloguePalette.brandGreen.withOpacity(0.02),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar.large(
                backgroundColor: CataloguePalette.background,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: CataloguePalette.brandGreen, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Plant Catalogue',
                  style: TextStyle(
                    color: CataloguePalette.brandGreen,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isLoading 
                            ? const SizedBox.shrink()
                            : Text(
                                'Showing ${filtered.length} botanical remedies',
                                key: ValueKey(filtered.length),
                                style: const TextStyle(
                                  color: CataloguePalette.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CupertinoActivityIndicator(radius: 16, color: CataloguePalette.brandGreen),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85, 
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final plant = filtered[index];
                        // Cycle through our botanical tints for each card
                        final cardColor = CataloguePalette.botanicalTints[index % CataloguePalette.botanicalTints.length];
                        
                        return _BotanicalPlantCard(
                          plant: plant,
                          backgroundColor: cardColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlantDetailScreen(plant: plant),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: CataloguePalette.searchBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CataloguePalette.brandGreen.withOpacity(0.05), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: CataloguePalette.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: CataloguePalette.brandGreen, size: 22),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.cancel_rounded, color: CataloguePalette.brandGreen.withOpacity(0.5), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          hintText: 'Search plants or symptoms...',
          hintStyle: TextStyle(color: CataloguePalette.brandGreen.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CataloguePalette.botanicalTints[0],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.energy_savings_leaf_outlined,
                size: 48,
                color: CataloguePalette.brandGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _loadError != null ? 'Connection Issue' : 'No Plants Found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CataloguePalette.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Try adjusting your search terms to find what you are looking for.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CataloguePalette.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 32),
            if (_loadError != null)
              ElevatedButton.icon(
                onPressed: _loadPlants,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CataloguePalette.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Lush Botanical Card ---
class _BotanicalPlantCard extends StatefulWidget {
  final Plant plant;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _BotanicalPlantCard({
    required this.plant,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  State<_BotanicalPlantCard> createState() => _BotanicalPlantCardState();
}

class _BotanicalPlantCardState extends State<_BotanicalPlantCard> {
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
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            // Replaced the gray border with a very soft green border
            border: Border.all(color: CataloguePalette.brandGreen.withOpacity(0.06), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: CataloguePalette.brandGreen.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Thicker, greener watermark to make it feel alive
                Positioned(
                  right: -25,
                  bottom: -25,
                  child: Icon(
                    Icons.grass_rounded,
                    size: 130,
                    color: CataloguePalette.brandGreen.withOpacity(0.06),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Icon Container - Now stark white to pop against the colored card
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_florist_rounded,
                          color: CataloguePalette.brandGreen,
                          size: 22,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      Text(
                        widget.plant.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CataloguePalette.textPrimary,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.plant.scientificName.isNotEmpty 
                            ? widget.plant.scientificName 
                            : (widget.plant.hint.isEmpty ? 'Tap to view details' : widget.plant.hint),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CataloguePalette.textSecondary,
                        ),
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