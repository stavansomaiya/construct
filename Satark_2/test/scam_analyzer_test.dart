import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:satark/models/analysis_result.dart';
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
      expect(result.category, 'Courier / parcel impersonation');
      expect(result.riskKey, isNot('low_indicators'));
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
    test('does not flag general OTP safety advice as a disclosure request', () {
      final result = ScamAnalyzer.analyze(
        'Never share your OTP with anyone. Your bank will never ask you for it.',
        language: 'English',
      );
      expect(result.riskKey, 'low_indicators');
      expect(result.category, 'General check');
    });

    test('generic delivery status wording is not treated as a confirmed scam', () {
      final result = ScamAnalyzer.analyze(
        'Your delivery status has changed. Please review the details using the link provided.',
        language: 'English',
      );
      expect(result.riskKey, isNot('high'));
    });

    test('flags secrecy and delayed payment procedure as review, not proof of fraud', () {
      final result = ScamAnalyzer.analyze(
        'I am from the department handling your case. Keep this conversation private and follow my instructions. We will explain the payment procedure after you join the video call.',
        language: 'English',
      );
      expect(result.riskKey, 'review');
      expect(result.riskKey, isNot('high'));
    });

    test('treats an unexpected account restriction claim as review rather than confirmed fraud', () {
      final result = ScamAnalyzer.analyze(
        'Your account has been temporarily restricted. Contact support using the number in this message to restore access.',
        language: 'English',
      );
      expect(result.riskKey, 'review');
    });

    test('does not alarm on an ordinary login OTP SMS', () {
      final result = ScamAnalyzer.analyze(
        '482913 is your OTP for login to HDFC NetBanking. Do not share OTP with anyone. - HDFC Bank',
        language: 'English',
      );
      expect(result.riskKey, 'low_indicators');
    });

    test('does not alarm on Hindi OTP safety advice', () {
      final result = ScamAnalyzer.analyze(
        'किसी को भी अपना ओटीपी न बताएं। बैंक कभी ओटीपी नहीं माँगता।',
        language: 'हिन्दी',
      );
      expect(result.riskKey, 'low_indicators');
    });

    test('a real OTP request is still caught when it follows safety advice', () {
      final result = ScamAnalyzer.analyze(
        'Do not share OTP with anyone. But tell me the OTP now so I can verify your account.',
        language: 'English',
      );
      expect(result.riskKey, isNot('low_indicators'));
    });

    test('flags remote-access app requests', () {
      final result = ScamAnalyzer.analyze(
        'Install AnyDesk and tell me the 9 digit code. I will fix your KYC issue from my side.',
        language: 'English',
      );
      expect(result.riskKey, isNot('low_indicators'));
    });

    test('a lone link is not enough to raise an alarm', () {
      final result = ScamAnalyzer.analyze(
        'Your Amazon order has shipped. Track it here: https://amzn.in/track/abc',
        language: 'English',
      );
      expect(result.riskKey, 'low_indicators');
    });

    test('high-risk results include the 1930 reporting step', () {
      final result = ScamAnalyzer.analyze(
        'I am calling from the CBI. Transfer money now to avoid arrest. Do not tell anyone.',
        language: 'English',
      );
      expect(result.nextSteps.last, contains('1930'));
    });

    test('never labels any result as safe', () {
      for (final text in ['hello', 'Your appointment is confirmed.', 'Pay now or be arrested by the CBI']) {
        for (final language in ['English', 'हिन्दी']) {
          final result = ScamAnalyzer.analyze(text, language: language);
          expect(result.riskLabel.toLowerCase(), isNot(contains('safe')));
          expect(result.riskLabel, isNot(contains('सुरक्षित')));
        }
      }
    });

    test('AnalysisResult survives a JSON round trip including AI fields', () {
      final base = ScamAnalyzer.analyze('Pay a registration fee for guaranteed returns', language: 'English');
      final withAi = base.copyWith(aiExplanation: 'Looks like an advance-fee scam.', aiAssisted: true);
      final restored = AnalysisResult.fromJson(withAi.toJson());
      expect(restored.aiExplanation, 'Looks like an advance-fee scam.');
      expect(restored.aiAssisted, isTrue);
      expect(restored.riskKey, base.riskKey);
      // Old saved history (without AI fields) must still load.
      final legacy = AnalysisResult.fromJson(base.toJson()..remove('aiExplanation')..remove('aiAssisted'));
      expect(legacy.aiAssisted, isFalse);
      expect(legacy.aiExplanation, isNull);
    });
  });

  group('Regression corpus (test/corpus/messages.json)', () {
    final raw = File('test/corpus/messages.json').readAsStringSync();
    final cases = (jsonDecode(raw)['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

    for (final item in cases) {
      test('${item['id']}', () {
        final result = ScamAnalyzer.analyze(item['text'] as String, language: item['lang'] as String);
        switch (item['expect'] as String) {
          case 'high':
            expect(result.riskKey, 'high', reason: 'score ${result.score}');
            break;
          case 'flag':
            expect(result.riskKey, isNot('low_indicators'), reason: 'score ${result.score}');
            break;
          default:
            expect(result.riskKey, 'low_indicators', reason: 'score ${result.score}');
        }
      });
    }
  });
}
