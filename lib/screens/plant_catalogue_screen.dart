import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import '../theme/app_colors.dart';
import '../widgets/leaf_bubble_card.dart';
import 'plant_detail_screen.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plant Catalogue'),
        backgroundColor: Color.fromARGB(255, 18, 54, 45),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.jungleGreenLight),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: AppColors.jungleGreen),
                  hintText: 'Search plants...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _isLoading
                    ? 'Loading plants...'
                    : 'Showing ${filtered.length} of ${_plants.length} plants',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.jungleGreen,
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_off,
                                  size: 42,
                                  color: AppColors.sunsetOrangeDark,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _loadError ??
                                      'No plants found for your current search.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _loadPlants,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.18,
                          ),
                          itemBuilder: (context, index) {
                            final plant = filtered[index];
                            return LeafBubbleCard(
                              title: plant.name,
                              subtitle: plant.hint.isEmpty
                                  ? 'Tap to view remedy details'
                                  : plant.hint,
                              color: index.isEven
                                  ? AppColors.jungleGreen
                                  : AppColors.sunsetOrangeDark,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: index.isEven
                                    ? AppColors.jungleGreen
                                    : AppColors.sunsetOrangeDark,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlantDetailScreen(plant: plant),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
