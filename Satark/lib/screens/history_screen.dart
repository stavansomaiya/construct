import 'package:flutter/material.dart';

import '../app.dart';
import '../models/analysis_result.dart';
import '../services/local_store.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all saved checks?'),
        content: const Text('This removes the local Satark history stored on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete all')),
        ],
      ),
    );
    if (ok == true) {
      await LocalStore.clearHistory();
      if (mounted) setState(() {});
    }
  }

  Color _color(String key) {
    if (key == 'high') return const Color(0xFFB3261E);
    if (key == 'review') return const Color(0xFF9A5B00);
    return satarkTeal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved checks'),
        actions: [IconButton(onPressed: _clearHistory, tooltip: 'Delete all history', icon: const Icon(Icons.delete_outline))],
      ),
      body: FutureBuilder<bool>(
        future: LocalStore.isHistoryEnabled(),
        builder: (context, enabledSnapshot) {
          final enabled = enabledSnapshot.data ?? false;
          if (!enabledSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!enabled) {
            return _emptyState(
              icon: Icons.lock_outline,
              title: 'History is off',
              text: 'Turn on optional encrypted local history in Settings if you want to review earlier checks.',
            );
          }
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: LocalStore.getHistory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final entries = snapshot.data!;
              if (entries.isEmpty) {
                return _emptyState(
                  icon: Icons.history,
                  title: 'No saved checks yet',
                  text: 'When history is enabled, your recent checks will appear here. History is stored only on this device.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final raw = entry['result'];
                  if (raw is! Map<String, dynamic>) return const SizedBox.shrink();
                  final result = AnalysisResult.fromJson(raw);
                  final savedAt = DateTime.tryParse(entry['savedAt']?.toString() ?? '');
                  final preview = result.originalText.replaceAll(RegExp(r'\s+'), ' ');
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ResultScreen(result: result))),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(width: 10, height: 48, decoration: BoxDecoration(color: _color(result.riskKey), borderRadius: BorderRadius.circular(10))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(result.riskLabel, style: TextStyle(fontWeight: FontWeight.w900, color: _color(result.riskKey), letterSpacing: 0.3)),
                                  const SizedBox(height: 4),
                                  Text(result.category, style: const TextStyle(fontWeight: FontWeight.w700)),
                                ])),
                                const Icon(Icons.chevron_right, color: Color(0xFF7C8290)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(preview, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
                            if (savedAt != null) ...[
                              const SizedBox(height: 9),
                              Text('${savedAt.day.toString().padLeft(2, '0')}/${savedAt.month.toString().padLeft(2, '0')}/${savedAt.year}  •  ${savedAt.hour.toString().padLeft(2, '0')}:${savedAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Color(0xFF777E90))),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String text}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: satarkTeal.withOpacity(0.10), shape: BoxShape.circle), child: Icon(icon, size: 38, color: satarkTeal)),
              const SizedBox(height: 18),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF626A7F), height: 1.5)),
            ],
          ),
        ),
      );
}
