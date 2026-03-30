import 'package:flutter/material.dart';
import '../screens/plant_assistant_screen.dart';

class LeafChatbotFab extends StatelessWidget {
  const LeafChatbotFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'leafChatFab',
      backgroundColor: const Color(0xFF2E7D32),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PlantAssistantScreen(),
          ),
        );
      },
      child: const Icon(Icons.spa, color: Colors.white),
    );
  }
}
