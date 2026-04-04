import 'dart:io';

import 'package:flutter/material.dart';

import '../services/scan_history_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final ScanHistoryService _scanHistoryService = ScanHistoryService();
  late Future<List<ScanHistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _scanHistoryService.getHistory();
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  void _openHistoryDetail(ScanHistoryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ScanHistoryDetailScreen(
          entry: entry,
          formattedTimestamp: _formatTimestamp(entry.timestamp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: const Color.fromARGB(255, 18, 54, 45),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ScanHistoryEntry>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? const <ScanHistoryEntry>[];
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No scans yet.\nYour scan results will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 18, 54, 45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final confidence = (entry.confidence * 100).toStringAsFixed(1);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openHistoryDetail(entry),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF558B6E).withOpacity(0.5),
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF558B6E),
                      child: Icon(Icons.eco, color: Colors.white),
                    ),
                    title: Text(
                      entry.plantName == null
                          ? 'No predicted plant'
                          : entry.plantName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 18, 54, 45),
                      ),
                    ),
                    subtitle: Text(
                      'Confidence: $confidence%\n${_formatTimestamp(entry.timestamp)}',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 91, 45, 23),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF558B6E),
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ScanHistoryDetailScreen extends StatelessWidget {
  final ScanHistoryEntry entry;
  final String formattedTimestamp;

  const _ScanHistoryDetailScreen({
    required this.entry,
    required this.formattedTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = (entry.confidence * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: const Text('Scan Details'),
        backgroundColor: const Color.fromARGB(255, 18, 54, 45),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Predicted Plant',
              value: entry.plantName ?? 'No predicted plant',
            ),
            if ((entry.scientificName ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoCard(
                title: 'Scientific Name',
                value: entry.scientificName!,
              ),
            ],
            const SizedBox(height: 10),
            _InfoCard(
              title: 'Predicted Time',
              value: formattedTimestamp,
            ),
            const SizedBox(height: 10),
            _InfoCard(
              title: 'Confidence',
              value: '$confidence%',
            ),
            if ((entry.message ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoCard(
                title: 'Message',
                value: entry.message!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final path = (entry.imagePath ?? '').trim();
    if (path.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF558B6E).withOpacity(0.4)),
        ),
        child: const Center(
          child: Text(
            'No prediction image available',
            style: TextStyle(
              color: Color.fromARGB(255, 91, 45, 23),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final file = File(path);
    final exists = file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 220,
        width: double.infinity,
        color: Colors.white,
        child: exists
            ? Image.file(file, fit: BoxFit.cover)
            : const Center(
                child: Text(
                  'Image file not found',
                  style: TextStyle(
                    color: Color.fromARGB(255, 91, 45, 23),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF558B6E).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color.fromARGB(255, 18, 54, 45),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color.fromARGB(255, 91, 45, 23),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
