import 'package:flutter/material.dart';
import '../services/plant_service.dart';
import '../theme/app_colors.dart';
import 'condition_remedies_screen.dart';

class HealthConditionsScreen extends StatefulWidget {
  const HealthConditionsScreen({super.key});

  @override
  State<HealthConditionsScreen> createState() => _HealthConditionsScreenState();
}

class _HealthConditionsScreenState extends State<HealthConditionsScreen> {
  final PlantService _plantService = PlantService();

  List<String> _conditions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConditions();
  }

  Future<void> _loadConditions() async {
    final conditions = await _plantService.fetchConditions();
    if (!mounted) return;
    setState(() {
      _conditions = conditions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Conditions'),
        backgroundColor: Color.fromARGB(255, 18, 54, 45),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.jungleGreen),
              )
            : GridView.builder(
                itemCount: _conditions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.45,
                ),
                itemBuilder: (context, index) {
                  final condition = _conditions[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ConditionRemediesScreen(condition: condition),
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? AppColors.bubbleGreen
                            : AppColors.bubbleOrange,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: index.isEven
                              ? AppColors.jungleGreen
                              : AppColors.sunsetOrangeDark,
                        ),
                      ),
                      child: Text(
                        condition,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
