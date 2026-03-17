import 'package:flutter/material.dart';

class PlantDetailScreen extends StatelessWidget {
  final String plantName;

  const PlantDetailScreen({super.key, required this.plantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Text(plantName),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              const Text(
                'MITI DAWA',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                plantName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 240,
                  width: double.infinity,
                  color: const Color(0xFFC8E6C9),
                  child: const Icon(Icons.local_florist,
                      size: 90, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 18),
              _bubble('Scientific Name', '$plantName officinalis'),
              _bubble('Common Uses',
                  'Skin care, digestion support, mild immunity support'),
              _bubble('Preparation',
                  'Boil leaves in water for tea or use paste externally'),
              _bubble('Caution',
                  'Use in moderation and consult a medical professional'),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Catalogue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
