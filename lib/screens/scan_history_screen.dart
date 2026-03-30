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

              return Container(
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
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
