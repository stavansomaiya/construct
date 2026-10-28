import 'package:flutter_test/flutter_test.dart';
import 'package:satark/services/scam_analyzer.dart';

void main() {
  group('ScamAnalyzer', () {
    test('flags authority impersonation with payment pressure as high risk', () {
      final result = ScamAnalyzer.analyze(
        'I am from the CBI. Transfer money now to avoid arrest. Do not tell anyone.',
        language: 'English',
      );
      expect(result.riskKey, 'high');
      expect(result.evidence, isNotEmpty);
      expect(result.riskLabel, 'HIGH RISK');
    });

    test('detects bank OTP warning signs', () {
      final result = ScamAnalyzer.analyze(
        'Your bank account will be blocked. Share your OTP immediately.',
        language: 'English',
      );
      expect(result.category, isNot('General check'));
      expect(result.warningSigns, isNotEmpty);
    });

    test('detects UPI collect request patterns', () {
      final result = ScamAnalyzer.analyze(
        'Approve this UPI collect request to receive your refund.',
        language: 'English',
      );
      expect(result.riskKey, isNot('low_indicators'));
    });


    test('detects courier fee and parcel pressure patterns', () {
      final result = ScamAnalyzer.analyze(
        'Your parcel is held by customs. Pay an urgent fee to release it.',
        language: 'English',
      );

      expect(
        result.category,
        anyOf(
          'Courier / parcel impersonation',
          'Multiple warning patterns',
        ),
      );
      expect(result.riskKey, 'high');
      expect(result.warningSigns, isNotEmpty);
    });

    test('detects upfront fee job and investment offers', () {
      final result = ScamAnalyzer.analyze(
        'Work from home job offer: pay a registration fee today for guaranteed returns.',
        language: 'English',
      );
      expect(result.category, isNot('General check'));
      expect(result.riskKey, isNot('low_indicators'));
    });

    test('classifies the parcel-on-hold payment-link example as high risk', () {
      final result = ScamAnalyzer.analyze(
        'Your parcel is on hold because your address is incomplete. '
        'Pay ₹25 immediately using this link or your package will be returned today.',
        language: 'English',
      );
      expect(result.category, isNot('General check'));
      expect(result.riskKey, 'high');
      expect(result.warningSigns, isNotEmpty);
    });

    test('classifies guaranteed-return upfront payment as high risk', () {
      final result = ScamAnalyzer.analyze(
        'Earn ₹8,000 every day by investing ₹2,000 today. Guaranteed returns. '
        'Send the money immediately to reserve your position.',
        language: 'English',
      );
      expect(result.category, isNot('General check'));
      expect(result.riskKey, 'high');
      expect(result.warningSigns, isNotEmpty);
    });

    test('does not claim a low-warning message is safe', () {
      final result = ScamAnalyzer.analyze(
        'Your appointment is confirmed for Tuesday at 3 pm.',
        language: 'English',
      );
      expect(result.riskKey, 'low_indicators');
      expect(result.riskLabel.toLowerCase(), isNot(contains('safe')));
      expect(result.disclaimer.toLowerCase(), contains('not a guarantee'));
    });

    test('supports Hindi warnings', () {
      final result = ScamAnalyzer.analyze(
        'मैं सीबीआई अधिकारी हूँ। अभी पैसे भेजें और किसी को मत बताना।',
        language: 'हिन्दी',
      );
      expect(result.riskKey, 'high');
      expect(result.riskLabel, 'उच्च जोखिम');
      expect(result.nextSteps.first, contains('ओटीपी'));
    });
  });
}
