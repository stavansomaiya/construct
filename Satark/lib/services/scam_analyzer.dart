import '../models/analysis_result.dart';

class _Rule {
  const _Rule({
    required this.category,
    required this.pattern,
    required this.reasonEnglish,
    required this.reasonHindi,
    required this.weight,
  });

  final String category;
  final RegExp pattern;
  final String reasonEnglish;
  final String reasonHindi;
  final int weight;
}

/// Transparent, offline-first MVP rules. This is not a trained AI model and
/// must never be presented as proof that a message is safe.
class ScamAnalyzer {
  static final List<_Rule> _rules = [
    _Rule(
      category: 'Digital arrest / authority impersonation',
      pattern: RegExp(r'digital arrest|\bpolice\b|\bcbi\b|central bureau of investigation|enforcement directorate|\bed officer\b|\barrest(?:ed)?\b|case registered|video call.{0,35}(officer|police|cbi)|पुलिस|सीबीआई|गिरफ्तार|डिजिटल अरेस्ट|केस दर्ज|जांच अधिकारी', caseSensitive: false),
      reasonEnglish: 'Claims of police or official authority can be used to frighten someone into acting quickly.',
      reasonHindi: 'पुलिस या सरकारी अधिकारी होने का दावा करके डर और जल्दबाज़ी पैदा की जा सकती है।',
      weight: 3,
    ),
    _Rule(
      category: 'Bank / KYC / OTP',
      pattern: RegExp(r'\botp\b|one[- ]time password|\bkyc\b|\bcvv\b|atm pin|upi pin|bank.{0,30}(blocked|suspend|freeze| बंद|रोक)|account.{0,25}(blocked|suspend|freeze)|verify.{0,20}(bank|account)|ओटीपी|केवाईसी|बैंक खाता|खाता बंद|पिन साझा|आधार कार्ड', caseSensitive: false),
      reasonEnglish: 'Requests for OTPs, PINs, or urgent account verification are a warning sign.',
      reasonHindi: 'ओटीपी, पिन या खाते के तुरंत सत्यापन की माँग चेतावनी का संकेत है।',
      weight: 3,
    ),
    _Rule(
      category: 'UPI / payment request',
      pattern: RegExp(r'collect request|upi.{0,25}(pin|request|refund|qr)|scan.{0,25}(qr|code).{0,25}(receive|get|refund)|refund.{0,25}(qr|upi|pin)|approve.{0,25}(collect|payment)|receive money.{0,25}(pin|upi)|यूपीआई|क्यूआर कोड|पैसे पाने के लिए पिन|कलेक्ट रिक्वेस्ट|पेमेंट अप्रूव', caseSensitive: false),
      reasonEnglish: 'A QR scan, collect request, or PIN request may be used to make you send money instead of receive it.',
      reasonHindi: 'क्यूआर कोड, कलेक्ट रिक्वेस्ट या पिन माँगकर आपसे पैसे भेजवाए जा सकते हैं।',
      weight: 3,
    ),
    _Rule(
      category: 'Courier / parcel impersonation',
      pattern: RegExp(r'(courier|parcel|customs|custom duty|fedex|dhl|india post|delivery).{0,75}(held|on hold|seized|fee|pay|police|case|urgent|blocked|address is incomplete)|(?:held|on hold|seized|illegal).{0,35}(parcel|package)|कूरियर|पार्सल|कस्टम ड्यूटी|डाक विभाग|पार्सल जब्त|डिलीवरी शुल्क', caseSensitive: false),
      reasonEnglish: 'A parcel problem paired with an urgent fee, police threat, or demand for details deserves independent verification.',
      reasonHindi: 'पार्सल की समस्या के साथ तुरंत शुल्क, पुलिस की धमकी या निजी जानकारी की माँग की जाँच करें।',
      weight: 2,
    ),
    _Rule(
      category: 'Job / investment offer',
      pattern: RegExp(r'job offer|work from home|registration fee|pay.{0,35}(to get|for the job|joining|registration|fee)|security deposit|guaranteed returns|double (your )?money|risk[- ]free|daily profit|crypto|investment plan|earn.{0,35}(per day|daily)|invest.{0,35}(today|now|immediately)|नौकरी|रजिस्ट्रेशन फीस|सिक्योरिटी डिपॉजिट|गारंटीड रिटर्न|पैसे दोगुने|निवेश योजना|रोज़ कमाएँ', caseSensitive: false),
      reasonEnglish: 'Upfront fees, guaranteed returns, or pressure to invest can indicate a fake offer.',
      reasonHindi: 'पहले शुल्क, गारंटीड मुनाफ़ा या निवेश का दबाव नकली ऑफर का संकेत हो सकता है।',
      weight: 2,
    ),
  ];

  static final List<_Rule> _redFlags = [
    _Rule(
      category: 'Urgency or threat',
      pattern: RegExp(r'right now|immediately|within \d+ (minute|hour)|last chance|urgent|otherwise.{0,20}(arrest|block|lose)|arrest you|account will be blocked|अभी तुरंत|तुरंत भुगतान|आज ही|गिरफ्तार कर|खाता बंद कर|आखिरी मौका', caseSensitive: false),
      reasonEnglish: 'Urgency or threats are often used to prevent a person from checking first.',
      reasonHindi: 'जल्दबाज़ी या धमकी देकर पहले जाँच करने से रोका जा सकता है।',
      weight: 2,
    ),
    _Rule(
      category: 'Secrecy or isolation',
      pattern: RegExp(r'do not tell|don.t tell anyone|keep this confidential|do not disconnect|stay on the call|tell your family|किसी को मत बताना|परिवार को मत बताना|कॉल मत काटना|गोपनीय रखें', caseSensitive: false),
      reasonEnglish: 'Instructions to keep it secret or stay on a call isolate the recipient from help.',
      reasonHindi: 'गुप्त रखने या कॉल न काटने की बात व्यक्ति को मदद लेने से रोक सकती है।',
      weight: 2,
    ),
    _Rule(
      category: 'Money or sensitive data demand',
      pattern: RegExp(r'transfer (the )?money|pay\b.{0,30}(now|immediately|fee|₹|rs\.?|rupees)|send (the )?money|share (your )?(otp|pin|password)|tell me (the )?otp|verification fee|release your account|bank details|upfront payment|pay in advance|पैसे भेजें|रकम ट्रांसफर|ओटीपी बताएं|पिन साझा|पासवर्ड बताएं|खाता खोलने का शुल्क|अभी पैसे|तुरंत पैसे', caseSensitive: false),
      reasonEnglish: 'A request for money, OTPs, passwords, or bank details is a high-impact warning sign.',
      reasonHindi: 'पैसे, ओटीपी, पासवर्ड या बैंक विवरण की माँग गंभीर चेतावनी है।',
      weight: 3,
    ),
    _Rule(
      category: 'Suspicious link',
      pattern: RegExp(r'https?://|bit\.ly/|tinyurl\.com|click here|tap this link|लिंक पर क्लिक', caseSensitive: false),
      reasonEnglish: 'An unexpected link should be checked independently before opening.',
      reasonHindi: 'अनजान लिंक खोलने से पहले स्वतंत्र रूप से जाँच करें।',
      weight: 2,
    ),
  ];

  static AnalysisResult analyze(String input, {required String language}) {
    final text = input.trim();
    final isHindi = language == 'हिन्दी';
    final foundRules = <_Rule>[];
    final evidence = <String>[];
    final reasons = <String>[];
    var score = 0;

    for (final rule in [..._rules, ..._redFlags]) {
      final match = rule.pattern.firstMatch(text);
      if (match == null) continue;
      foundRules.add(rule);
      score += rule.weight;
      final snippet = _contextSnippet(text, match.start, match.end);
      if (snippet.isNotEmpty && !evidence.contains(snippet)) evidence.add(snippet);
      final reason = isHindi ? rule.reasonHindi : rule.reasonEnglish;
      if (!reasons.contains(reason)) reasons.add(reason);
    }

    // Some repeated words can trigger multiple patterns. Keep the result
    // conservative, with direct-payment / authority combinations weighted up.
    final categoryRules = foundRules.where((r) => _rules.contains(r)).toList();
    final hasAuthority = categoryRules.any((r) => r.category.startsWith('Digital arrest'));
    final hasMoneyDemand = foundRules.any((r) => r.category == 'Money or sensitive data demand');
    final hasUrgency = foundRules.any((r) => r.category == 'Urgency or threat');
    if (hasAuthority && (hasMoneyDemand || hasUrgency)) score += 2;

    final riskKey = score >= 5
        ? 'high'
        : score >= 2
            ? 'review'
            : 'low_indicators';

    String category;
    if (categoryRules.isEmpty) {
      category = isHindi ? 'सामान्य जाँच' : 'General check';
    } else {
      category = categoryRules.first.category;
      if (categoryRules.length > 1) {
        category = isHindi ? 'कई प्रकार के चेतावनी संकेत' : 'Multiple warning patterns';
      }
    }
    if (isHindi && categoryRules.length == 1) {
      category = _hindiCategory(categoryRules.first.category);
    }

    final List<String> nextSteps;
    if (isHindi) {
      nextSteps = [
        'पैसे ट्रांसफर न करें और ओटीपी, पिन या पासवर्ड साझा न करें।',
        'दबाव डालने वाले कॉल या चैट को रोकें; किसी धमकी को तुरंत सच न मानें।',
        'आधिकारिक ऐप, कार्ड या वेबसाइट पर दिए नंबर से स्वतंत्र रूप से सत्यापन करें।',
        'शक बना रहे तो किसी भरोसेमंद व्यक्ति से बात करें।',
      ];
    } else {
      nextSteps = [
        'Do not transfer money or share an OTP, PIN, password, or banking details.',
        'End a pressured call or chat. Do not treat a threat as proof that the caller is genuine.',
        'Verify independently using a number from the official app, card, or website—not one supplied in the message.',
        'If you are unsure, speak to someone you trust before taking action.',
      ];
    }

    if (reasons.isEmpty) {
      reasons.add(isHindi
          ? 'इस सरल जाँच में कोई स्पष्ट ज्ञात चेतावनी पैटर्न नहीं मिला।'
          : 'This basic check did not find an obvious known warning pattern.');
    }

    final summary = isHindi
        ? (riskKey == 'high'
            ? 'इस संदेश में कई गंभीर चेतावनी संकेत हैं। अभी पैसे न भेजें और निजी जानकारी साझा न करें। स्वतंत्र रूप से जाँच करें।'
            : riskKey == 'review'
                ? 'कुछ चेतावनी संकेत मिले हैं। कोई कदम उठाने से पहले संदेश की स्वतंत्र रूप से जाँच करें।'
                : 'इस सरल जाँच में कम चेतावनी संकेत मिले। इसका अर्थ यह नहीं है कि संदेश सुरक्षित है; स्वतंत्र रूप से सत्यापन करें।')
        : (riskKey == 'high'
            ? 'This message has several serious warning signs. Do not send money or share private information. Verify independently.'
            : riskKey == 'review'
                ? 'Some warning signs were found. Verify the message independently before taking action.'
                : 'This basic check found fewer warning signs. That does not mean the message is safe; verify independently.');

    return AnalysisResult(
      originalText: text,
      language: language,
      riskKey: riskKey,
      category: category,
      score: score,
      evidence: evidence.take(5).toList(),
      warningSigns: reasons.take(6).toList(),
      nextSteps: nextSteps,
      spokenSummary: summary,
      disclaimer: isHindi
          ? 'यह प्रारंभिक नियम-आधारित जाँच है, गारंटी नहीं। गलत अलर्ट या छूटे हुए संकेत संभव हैं। किसी संदेश को निश्चित रूप से सुरक्षित नहीं कहा जा सकता।'
          : 'This is an initial rule-based check, not a guarantee. False alarms and missed signals are possible. No message can be declared guaranteed safe.',
    );
  }

  static String _hindiCategory(String english) {
    switch (english) {
      case 'Digital arrest / authority impersonation': return 'डिजिटल अरेस्ट / अधिकारी बनकर धोखाधड़ी';
      case 'Bank / KYC / OTP': return 'बैंक / केवाईसी / ओटीपी';
      case 'UPI / payment request': return 'यूपीआई / भुगतान अनुरोध';
      case 'Courier / parcel impersonation': return 'कूरियर / पार्सल धोखाधड़ी';
      case 'Job / investment offer': return 'नौकरी / निवेश ऑफर';
      default: return english;
    }
  }

  static String _contextSnippet(String text, int start, int end) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ');
    // Recalculate against normalized text when line breaks exist.
    final normalizedStart = text.substring(0, start).replaceAll(RegExp(r'\s+'), ' ').length;
    final normalizedEnd = text.substring(0, end).replaceAll(RegExp(r'\s+'), ' ').length;
    final left = (normalizedStart - 24).clamp(0, clean.length).toInt();
    final right = (normalizedEnd + 24).clamp(0, clean.length).toInt();
    var snippet = clean.substring(left, right).trim();
    if (left > 0) snippet = '…$snippet';
    if (right < clean.length) snippet = '$snippet…';
    return snippet;
  }
}
