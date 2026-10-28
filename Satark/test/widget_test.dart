import 'package:flutter_test/flutter_test.dart';
import 'package:satark/services/scam_analyzer.dart';

void main() {
  test('Satark analyzer returns a cautious result for a normal message', () {
    final result = ScamAnalyzer.analyze(
      'Your appointment is confirmed for tomorrow at 10:30 AM.',
      language: 'English',
    );

    expect(result.riskKey, 'low_indicators');
    expect(result.riskLabel, 'FEWER WARNING SIGNS');
    expect(result.disclaimer, contains('not a guarantee'));
  });
}
