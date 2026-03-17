import 'package:flutter/material.dart';

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
        color: const Color(0xFFE8F5E9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(30),
        ),
        border: Border.all(color: const Color(0xFF66BB6A), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Color(0xFF2E7D32)),
          hintText: 'Search remedy, plant or condition...',
          border: InputBorder.none,
        ),
      ),
    );
  }
}
