import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/plant_service.dart';
import 'condition_remedies_screen.dart';

class HealthConditionsScreen extends StatefulWidget {
  const HealthConditionsScreen({super.key});

  @override
  State<HealthConditionsScreen> createState() => _HealthConditionsScreenState();
}

class _HealthConditionsScreenState extends State<HealthConditionsScreen> {
  final PlantService _plantService = PlantService();
  final TextEditingController _searchController = TextEditingController();

  List<String> _conditions = [];
  bool _isLoading = true;
  String _query = '';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadConditions();
  }

  Future<void> _loadConditions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final conditions = await _plantService.fetchConditions();
      if (!mounted) return;
      setState(() {
        _conditions = conditions;
        _loadError = conditions.isEmpty ? 'No conditions found.' : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _conditions = [];
        _loadError = 'Could not load conditions right now.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _conditions.where((c) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -100,
            child: Icon(
              Icons.spa_rounded,
              size: 350,
              color: const Color(0xFF1E4D3B).withOpacity(0.02),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar.large(
                backgroundColor: const Color(0xFFF3F7F4),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF1E4D3B),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Health Conditions',
                  style: TextStyle(
                    color: Color(0xFF1E4D3B),
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
                                'Showing ${filtered.length} conditions',
                                key: ValueKey(filtered.length),
                                style: const TextStyle(
                                  color: Color(0xFF6B8074),
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
                    child: CupertinoActivityIndicator(radius: 16, color: Color(0xFF1E4D3B)),
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
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final condition = filtered[index];
                        final tints = <Color>[
                          const Color(0xFFE8F1EC),
                          const Color(0xFFEBF2E3),
                          const Color(0xFFF2EFE8),
                          const Color(0xFFE2EBE5),
                        ];
                        return _ConditionCard(
                          condition: condition,
                          backgroundColor: tints[index % tints.length],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConditionRemediesScreen(condition: condition),
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
        color: const Color(0xFFE6EFE9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E4D3B).withOpacity(0.05), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: Color(0xFF1A3324), fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E4D3B), size: 22),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.cancel_rounded, color: const Color(0xFF1E4D3B).withOpacity(0.5), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          hintText: 'Search conditions...',
          hintStyle: TextStyle(
            color: const Color(0xFF1E4D3B).withOpacity(0.4),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
              decoration: const BoxDecoration(
                color: Color(0xFFE8F1EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                size: 48,
                color: Color(0xFF1E4D3B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _loadError != null ? 'No Conditions Found' : 'No Conditions Found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A3324),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Try adjusting your search terms.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B8074), height: 1.4),
            ),
            const SizedBox(height: 32),
            if (_loadError != null)
              ElevatedButton.icon(
                onPressed: _loadConditions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4D3B),
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

class _ConditionCard extends StatefulWidget {
  final String condition;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ConditionCard({
    required this.condition,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  State<_ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<_ConditionCard> {
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
            border: Border.all(color: const Color(0xFF1E4D3B).withOpacity(0.06), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E4D3B).withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -25,
                  bottom: -25,
                  child: Icon(
                    Icons.healing_rounded,
                    size: 120,
                    color: const Color(0xFF1E4D3B).withOpacity(0.06),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monitor_heart_outlined,
                          color: Color(0xFF1E4D3B),
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.condition,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A3324),
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap to view remedies',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B8074),
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
