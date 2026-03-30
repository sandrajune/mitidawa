import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LeafSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const LeafSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.jungleGreenLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(30),
        ),
        border: Border.all(color: AppColors.jungleGreen, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: AppColors.jungleGreen),
          hintText: 'Search remedy, plant or condition...',
          border: InputBorder.none,
        ),
      ),
    );
  }
}
