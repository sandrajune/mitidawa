import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import '../theme/app_colors.dart';
import '../widgets/leaf_bubble_card.dart';
import 'plant_detail_screen.dart';

class ConditionRemediesScreen extends StatefulWidget {
  final String condition;

  const ConditionRemediesScreen({
    super.key,
    required this.condition,
  });

  @override
  State<ConditionRemediesScreen> createState() =>
      _ConditionRemediesScreenState();
}

class _ConditionRemediesScreenState extends State<ConditionRemediesScreen> {
  final PlantService _plantService = PlantService();

  List<Plant> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants =
        await _plantService.fetchPlantsForCondition(widget.condition);
    if (!mounted) return;
    setState(() {
      _plants = plants;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.condition),
        backgroundColor: Color.fromARGB(255, 18, 54, 45),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.jungleGreen),
              )
            : _plants.isEmpty
                ? const Center(
                    child: Text(
                      'No remedy plants found for this condition.',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  )
                : GridView.builder(
                    itemCount: _plants.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.18,
                    ),
                    itemBuilder: (context, index) {
                      final plant = _plants[index];
                      return LeafBubbleCard(
                        title: plant.name,
                        subtitle: plant.hint.isEmpty
                            ? 'Tap to view remedy details'
                            : plant.hint,
                        color: index.isEven
                            ? AppColors.bubbleGreen
                            : AppColors.bubbleGreen,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: index.isEven
                              ? AppColors.jungleGreen
                              : AppColors.jungleGreen,
                        ),
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
                  ),
      ),
    );
  }
}
