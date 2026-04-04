import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../theme/app_colors.dart';

class PredictionResultScreen extends StatelessWidget {
  final Plant? plant;
  final double confidence;
  final String? message;

  const PredictionResultScreen({
    super.key,
    required this.plant,
    required this.confidence,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrediction = plant != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: const Text('Prediction Result'),
        backgroundColor: const Color.fromARGB(255, 18, 54, 45),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF558B6E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF558B6E),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Confidence Score',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color.fromARGB(255, 18, 54, 45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color.fromARGB(255, 91, 45, 23),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!hasPrediction) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color.fromARGB(255, 91, 45, 23),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 34,
                        color: Color.fromARGB(255, 91, 45, 23),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No predicted plant',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color.fromARGB(255, 18, 54, 45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message ??
                            'Take a Picture of a Plant for Prediction.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 91, 45, 23),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _PlantShowcase(plant: plant!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantShowcase extends StatelessWidget {
  final Plant plant;

  const _PlantShowcase({required this.plant});

  @override
  Widget build(BuildContext context) {
    final imageUrls = <String>[
      plant.primaryImageUrl.trim(),
      plant.detailImageUrl.trim(),
    ].where((url) => url.isNotEmpty).toList();

    return Column(
      children: [
        const Text(
          'MITI DAWA',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.jungleGreenDark,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          plant.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.jungleGreen,
          ),
        ),
        const SizedBox(height: 20),
        _imageCarousel(imageUrls),
        const SizedBox(height: 18),
        _bubble('Scientific Name', plant.scientificName),
        _bubble('Description', plant.description),
        _localNamesBubble(plant.localNames),
        _usesBubble(plant.uses),
      ],
    );
  }

  Widget _imageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 240,
          width: double.infinity,
          color: AppColors.jungleGreenLight,
          child: const Icon(
            Icons.local_florist,
            size: 90,
            color: AppColors.jungleGreen,
          ),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.jungleGreenLight),
                  Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 56,
                          color: AppColors.jungleGreen,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}/${imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bubble(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.jungleGreen,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content.isEmpty ? 'Not available' : content,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _localNamesBubble(String localNames) {
    final names = _normalizeListText(localNames);
    if (names.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.jungleGreen,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Local Names',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final name in names)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $name',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _usesBubble(String uses) {
    final useLines = _normalizeListText(uses);
    if (useLines.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.jungleGreen,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uses',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in useLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  children: [
                    const TextSpan(text: '• '),
                    ..._parseUseLine(line),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _normalizeListText(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return [];

    if (raw.startsWith('[') && raw.endsWith(']')) {
      final inner = raw.substring(1, raw.length - 1).trim();
      if (inner.isEmpty) return [];
      return inner
          .split(RegExp(r'","|",\s*"|' ',s*' '|",s*|' ',s*'))
          .expand((part) => part.split(RegExp(r'[,\n\r]+')))
          .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return raw
        .split(RegExp(r'[,\n\r]+'))
        .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<TextSpan> _parseUseLine(String line) {
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) {
      return [TextSpan(text: line)];
    }
    final category = line.substring(0, colonIndex).trim();
    final desc = line.substring(colonIndex + 1).trim();
    return [
      TextSpan(
        text: category,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const TextSpan(text: ': '),
      TextSpan(text: desc),
    ];
  }
}
