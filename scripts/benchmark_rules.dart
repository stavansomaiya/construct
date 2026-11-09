import 'dart:convert';
import 'dart:io';

import '../Satark_2/lib/services/scam_analyzer.dart';

/// Reads [{message,label,language}, ...] JSON on stdin and emits aggregate
/// metrics. A review or high result counts as a positive scam alert.
void main() {
  final input = jsonDecode(stdin.readLineSync()!) as List<dynamic>;
  final rows = input.cast<Map<String, dynamic>>();
  var tp = 0, fp = 0, tn = 0, fn = 0;
  final byLanguage = <String, List<int>>{};
  final byRisk = <String, int>{};

  for (final row in rows) {
    final message = row['message'] as String;
    final label = (row['label'] as String).toLowerCase().trim();
    final language = (row['language'] as String?)?.trim();
    final result = ScamAnalyzer.analyze(message, language: 'English');
    final predictedScam = result.riskKey != 'low_indicators';
    final actualScam = label == 'scam';
    if (actualScam && predictedScam) {
      tp++;
    } else if (actualScam) {
      fn++;
    } else if (predictedScam) {
      fp++;
    } else {
      tn++;
    }
    byRisk.update(result.riskKey, (value) => value + 1, ifAbsent: () => 1);
    final counts = byLanguage.putIfAbsent(
      language ?? 'Unknown',
      () => [0, 0, 0, 0, 0, 0, 0],
    );
    counts[0]++;
    if (actualScam) counts[1]++;
    if (predictedScam) counts[2]++;
    if (actualScam && predictedScam) {
      counts[3]++;
    } else if (actualScam) {
      counts[6]++;
    } else if (predictedScam) {
      counts[4]++;
    } else {
      counts[5]++;
    }
  }

  final precision = tp + fp == 0 ? 0.0 : tp / (tp + fp);
  final recall = tp + fn == 0 ? 0.0 : tp / (tp + fn);
  final f1 = precision + recall == 0
      ? 0.0
      : 2 * precision * recall / (precision + recall);
  print(
    jsonEncode({
      'total': rows.length,
      'tp': tp,
      'fp': fp,
      'tn': tn,
      'fn': fn,
      'accuracy': (tp + tn) / rows.length,
      'precision': precision,
      'recall': recall,
      'f1': f1,
      'riskLevels': byRisk,
      'languages': {
        for (final entry in byLanguage.entries)
          entry.key: {
            'total': entry.value[0],
            'scams': entry.value[1],
            'flagged': entry.value[2],
            'tp': entry.value[3],
            'fp': entry.value[4],
            'tn': entry.value[5],
            'fn': entry.value[6],
            'recall': entry.value[1] == 0
                ? 0.0
                : entry.value[3] / entry.value[1],
          },
      },
    }),
  );
}
