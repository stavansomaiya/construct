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

/// Transparent, offline-first rules. This is not a trained AI model and must
/// never be presented as proof that a message is safe.
///
/// How it works, in plain words:
///  * Six "scam family" rules (digital arrest, bank/KYC/OTP, account restriction,
///    UPI, courier/parcel, job/investment) and several "red flag" rules (urgency,
///    secrecy, money demand, links, remote-access apps, prize claims).
///  * Each rule that matches adds its weight once. Score >= 5 is HIGH RISK,
///    >= 2 is CHECK CAREFULLY, anything lower is "fewer warning signs".
///  * Sentences that *warn against* scams ("Never share your OTP") are blanked out
///    before matching so safety advice is not mistaken for a request.
class ScamAnalyzer {
  static final List<_Rule> _rules = [
    _Rule(
      category: 'Digital arrest / authority impersonation',
      pattern: RegExp(r'digital arrest|\bcbi\b|central bureau of investigation|enforcement directorate|\bed officer\b|\bncb\b|narcotics|cyber ?crime (branch|cell|police|department|officer)|crime branch|case (has been |is |was )?(registered|filed|lodged)|arrest warrant|warrant (has been |is )?(issued|against)|money laundering|(aadhaar|sim|mobile number|phone number).{0,30}(used|linked|involved|misused).{0,30}(illegal|crime|fraud|laundering|terror)|video call.{0,35}(officer|police|cbi|inspector)|(officer|inspector).{0,40}video call|supreme court|\btrai\b.{0,40}(disconnect|block|illegal|suspend)|डिजिटल अरेस्ट|सीबीआई|ईडी अधिकारी|नारकोटिक्स|साइबर क्राइम|केस दर्ज|मनी लॉन्ड्रिंग|मनी लॉन्डरिंग|गिरफ्तारी (का )?वारंट|जांच अधिकारी|जाँच अधिकारी|सुप्रीम कोर्ट|ट्राई.{0,40}(बंद|ब्लॉक|अवैध)|आधार.{0,30}(अवैध|अपराध|धोखाधड़ी)', caseSensitive: false),
      reasonEnglish: 'Claims of police or official authority can be used to frighten someone into acting quickly.',
      reasonHindi: 'पुलिस या सरकारी अधिकारी होने का दावा करके डर और जल्दबाज़ी पैदा की जा सकती है।',
      weight: 3,
    ),
    _Rule(
      category: 'Bank / KYC / OTP',
      pattern: RegExp(r'(share|send|tell|give|read out|forward|provide|enter|submit|confirm|disclose).{0,25}\b(otp|pin|cvv|password|passcode|one[- ]time password)\b|\b(otp|pin|cvv|one[- ]time password)\b.{0,25}\b(share|send|tell|give|forward|read out)\b|(update|complete|verify|renew|expire|expiry|pending|blocked|suspend).{0,25}\bkyc\b|\bkyc\b.{0,25}(update|expire|pending|blocked|verify|incomplete|suspend|complete)|bank.{0,30}(blocked|suspend|freeze|deactivat)|verify.{0,20}(bank|account|aadhaar|pan)\b|ओटीपी.{0,25}(बताएं|बताइए|बताओ|बताइये|भेजें|भेजिए|शेयर|साझा|दीजिए|दें)|(बताएं|बताइए|बताओ|भेजें|साझा|शेयर).{0,25}(ओटीपी|पिन|सीवीवी|पासवर्ड)|(पिन|सीवीवी|पासवर्ड).{0,25}(बताएं|बताइए|भेजें|साझा|शेयर|दें)|केवाईसी.{0,25}(अपडेट|पूरा|बंद|एक्सपायर|सत्यापित)|(अपडेट|पूरा|सत्यापित).{0,25}केवाईसी|बैंक.{0,30}(बंद|ब्लॉक|रोक)|आधार कार्ड.{0,25}(अपडेट|सत्यापित|लिंक)', caseSensitive: false),
      reasonEnglish: 'Requests for OTPs, PINs, or urgent account verification are a warning sign.',
      reasonHindi: 'ओटीपी, पिन या खाते के तुरंत सत्यापन की माँग चेतावनी का संकेत है।',
      weight: 3,
    ),
    _Rule(
      category: 'Account restriction / support impersonation',
      pattern: RegExp(r'(account|profile|access|number|sim).{0,35}(temporarily )?(restricted|suspended|blocked|deactivated|disconnected)|contact (customer )?support.{0,40}(number|message)|call (this|the) (number|helpline).{0,30}(restore|unblock|reactivate)|(अकाउंट|खाता|प्रोफ़ाइल|सिम|नंबर).{0,30}(बंद|ब्लॉक|सस्पेंड|प्रतिबंधित|डिस्कनेक्ट)', caseSensitive: false),
      reasonEnglish: 'Unexpected restriction claims and contact details supplied in a message should be verified through the official app or website.',
      reasonHindi: 'अचानक खाते पर रोक का दावा और संदेश में दिया संपर्क नंबर आधिकारिक ऐप या वेबसाइट से जाँचें।',
      weight: 2,
    ),
    _Rule(
      category: 'UPI / payment request',
      pattern: RegExp(r'collect request|upi.{0,25}(pin|request|refund|qr)|scan.{0,25}(qr|code).{0,25}(receive|get|refund)|refund.{0,25}(qr|upi|pin)|approve.{0,25}(collect|payment|request)|receive money.{0,25}(pin|upi)|(sent|transferred|credited).{0,30}(by mistake|wrongly|wrong number).{0,60}(return|refund|send back)|(by mistake|wrongly).{0,40}(return|send back|refund)|(enter|share).{0,15}pin.{0,25}(receive|refund|get)|यूपीआई.{0,25}(पिन|रिक्वेस्ट|रिफंड|क्यूआर|अप्रूव)|क्यूआर कोड|पैसे पाने के लिए पिन|कलेक्ट रिक्वेस्ट|पेमेंट अप्रूव|गलती से.{0,40}(पैसे|रकम).{0,40}(लौटा|वापस)|रिफंड.{0,25}(पिन|क्यूआर|यूपीआई)', caseSensitive: false),
      reasonEnglish: 'A QR scan, collect request, or PIN request may be used to make you send money instead of receive it.',
      reasonHindi: 'क्यूआर कोड, कलेक्ट रिक्वेस्ट या पिन माँगकर आपसे पैसे भेजवाए जा सकते हैं।',
      weight: 3,
    ),
    _Rule(
      category: 'Courier / parcel impersonation',
      pattern: RegExp(r'(courier|parcel|package|customs|custom duty|fedex|dhl|blue dart|india post|delivery|consignment).{0,75}(held|on hold|seized|fee|duty|pay|police|case|urgent|blocked|address is incomplete|illegal|drugs|narcotic|passport|contraband|returned)|(held|on hold|seized|illegal|stuck).{0,35}(parcel|package|consignment)|(कूरियर|पार्सल|कस्टम|डाक).{0,60}(रोक|जब्त|शुल्क|ड्यूटी|भुगतान|पुलिस|अवैध|ड्रग|पासपोर्ट|मामला|केस|तुरंत|जमा)|(रोका|जब्त).{0,30}(पार्सल|कूरियर)', caseSensitive: false),
      reasonEnglish: 'A parcel problem paired with an urgent fee, police threat, or demand for details deserves independent verification.',
      reasonHindi: 'पार्सल की समस्या के साथ तुरंत शुल्क, पुलिस की धमकी या निजी जानकारी की माँग की जाँच करें।',
      weight: 2,
    ),
    _Rule(
      category: 'Job / investment offer',
      pattern: RegExp(r'job offer|work from home|part[- ]time job|registration fee|joining fee|training fee|security deposit|guaranteed returns?|double (your )?money|risk[- ]free|daily profit|crypto|investment plan|trading group|telegram.{0,40}(earn|profit|invest|task|job)|(earn|make).{0,35}(per day|daily|every day|a day)|invest.{0,35}(today|now|immediately)|like.{0,20}(videos?|posts?).{0,30}(earn|paid|pay)|pay.{0,35}(to get|for the job|joining|registration)|नौकरी|रजिस्ट्रेशन फीस|सिक्योरिटी डिपॉजिट|गारंटीड रिटर्न|पैसे दोगुने|निवेश योजना|(रोज़|रोज).{0,15}(कमाएं|कमाएँ|कमाई)|घर बैठे.{0,30}(कमाएं|कमाएँ)|टेलीग्राम', caseSensitive: false),
      reasonEnglish: 'Upfront fees, guaranteed returns, or pressure to invest can indicate a fake offer.',
      reasonHindi: 'पहले शुल्क, गारंटीड मुनाफ़ा या निवेश का दबाव नकली ऑफर का संकेत हो सकता है।',
      weight: 2,
    ),
  ];

  static final List<_Rule> _redFlags = [
    _Rule(
      category: 'Official-authority mention',
      pattern: RegExp(r'\bpolice\b|\barrest(ed)?\b|\bofficer\b|\binspector\b|पुलिस|गिरफ्तार|अधिकारी', caseSensitive: false),
      reasonEnglish: 'The message mentions police or an official. Real officials do not demand money or secrecy by phone or chat.',
      reasonHindi: 'संदेश में पुलिस या अधिकारी का ज़िक्र है। असली अधिकारी फ़ोन या चैट पर पैसे या गोपनीयता की माँग नहीं करते।',
      weight: 1,
    ),
    _Rule(
      category: 'Urgency or threat',
      pattern: RegExp(r'right now|immediately|within \d+ ?(minutes?|mins?|hours?|hrs?)|within (an|one|two|few) hours?|last chance|last warning|final notice|urgent(ly)?|today only|expires? (today|tonight|soon)|will be (disconnected|cut off|cut|blocked|suspended|deactivated)|otherwise.{0,20}(arrest|block|lose|cut|disconnect)|arrest you|account will be blocked|तुरंत|फौरन|फ़ौरन|आज ही|आज रात|जल्द से जल्द|\d+ ?घंटे (में|के अंदर)|गिरफ्तार कर|खाता बंद कर|आखिरी मौका|आख़िरी मौका|वरना.{0,30}(बंद|ब्लॉक|गिरफ्तार|कट)', caseSensitive: false),
      reasonEnglish: 'Urgency or threats are often used to prevent a person from checking first.',
      reasonHindi: 'जल्दबाज़ी या धमकी देकर पहले जाँच करने से रोका जा सकता है।',
      weight: 2,
    ),
    _Rule(
      category: 'Secrecy or isolation',
      pattern: RegExp(r'do not tell|don.t tell (anyone|any one|anybody|mom|dad|mum|papa|mama|your)|keep (this|it) (confidential|secret|private|between us)|keep this conversation private|do not disconnect|don.t disconnect|do not cut the call|stay on the (video )?(call|line)|किसी को (भी )?(मत|न) बता|परिवार (को|से).{0,15}(मत|न) बता|कॉल (मत|न) काट|कॉल पर बने रहें|कॉल पर बने रहिए|वीडियो कॉल पर बने|गोपनीय रखें|गुप्त रखें|किसी से बात (मत|न) करें', caseSensitive: false),
      reasonEnglish: 'Instructions to keep it secret or stay on a call isolate the recipient from help.',
      reasonHindi: 'गुप्त रखने या कॉल न काटने की बात व्यक्ति को मदद लेने से रोक सकती है।',
      weight: 2,
    ),
    _Rule(
      category: 'Money or sensitive data demand',
      pattern: RegExp(r'transfer (the )?money|transfer.{0,20}(₹|rs\.?|inr|rupees)|pay\b.{0,30}(now|immediately|fee|fine|charges?)|send (the )?money|(send|transfer|deposit).{0,6}(₹|rs\.?|inr)\s?\d|share (your )?(otp|pin|password)|tell me (the )?otp|verification (fee|charges?)|(processing|clearance|release|claim|registration|handling|customs?) (fee|charges?|duty)|release your account|bank details|upfront payment|pay in advance|safe account|rbi (safe )?account|secure account|पैसे (भेजें|भेजिए|ट्रांसफर|जमा)|रकम (ट्रांसफर|भेजें|जमा)|(पैसे|पैसा|रकम).{0,15}(भेज|ट्रांसफर|जमा)|(शुल्क|फीस|जुर्माना).{0,15}(जमा|भरें|भेजें|दें)|ओटीपी बताएं|पिन साझा|पासवर्ड बताएं|सेफ अकाउंट|सुरक्षित खाते|अभी पैसे|तुरंत पैसे|खाता खोलने का शुल्क', caseSensitive: false),
      reasonEnglish: 'A request for money, OTPs, passwords, or bank details is a high-impact warning sign.',
      reasonHindi: 'पैसे, ओटीपी, पासवर्ड या बैंक विवरण की माँग गंभीर चेतावनी है।',
      weight: 3,
    ),
    _Rule(
      category: 'Remote access or app install request',
      pattern: RegExp(r'any ?desk|team ?viewer|quick ?support|rust ?desk|ultra ?viewer|\bscreen ?shar(e|ing)\b|remote (access|control|support)|\.apk\b|एनीडेस्क|टीमव्यूअर|क्विक सपोर्ट|स्क्रीन शेयर|एपीके', caseSensitive: false),
      reasonEnglish: 'Installing a remote-access app or an APK file can give a stranger control of your phone and bank apps.',
      reasonHindi: 'रिमोट-एक्सेस ऐप या APK फ़ाइल इंस्टॉल करने से कोई अजनबी आपके फ़ोन और बैंक ऐप पर कंट्रोल पा सकता है।',
      weight: 3,
    ),
    _Rule(
      category: 'Prize or lottery claim',
      pattern: RegExp(r'lottery|you (have )?won|lucky draw|\bkbc\b|prize money|congratulations.{0,40}(won|winner|selected)|लॉटरी|इनाम (जीत|मिला)|आपने.{0,15}जीत', caseSensitive: false),
      reasonEnglish: 'Unexpected prize or lottery claims are a common way to get people to pay a fee or share details.',
      reasonHindi: 'अचानक इनाम या लॉटरी का दावा अक्सर शुल्क या निजी जानकारी लेने के लिए किया जाता है।',
      weight: 2,
    ),
    _Rule(
      category: 'Suspicious link',
      pattern: RegExp(r'https?://|\bwww\.|bit\.ly/|tinyurl\.com|\bt\.co/|cutt\.ly/|click (here|the link|below)|tap (this|the) link|लिंक पर क्लिक|इस लिंक', caseSensitive: false),
      reasonEnglish: 'An unexpected link should be checked independently before opening.',
      reasonHindi: 'अनजान लिंक खोलने से पहले स्वतंत्र रूप से जाँच करें।',
      weight: 1,
    ),
  ];

  /// Sentences that warn people AGAINST sharing OTPs / PINs. They contain the very
  /// words scam messages use, so they are blanked out before the rules run.
  static final RegExp _safetyAdvice = RegExp(r'(never|do not|don.t|should not|must not|please do not)\s+(ever\s+)?(share|tell|give|disclose|reveal|send|forward)\s+(your\s+|the\s+|this\s+|any\s+)?(\w+\s+){0,2}(otp|pin|cvv|password|passcode)\b(\s+(with|to)\s+(anyone|anybody|any one|others?|no one|strangers?|callers?|unknown (persons?|callers?)))?|\b(will|would|shall)\s+never\s+ask\b[^.!?;,:]{0,25}|(किसी को|किसी से)\s+(भी\s+)?(अपना\s+)?(ओटीपी|पिन|सीवीवी|पासवर्ड)[^.।!?]{0,25}(न|ना|मत)\s*(बताएं|बताइए|बताना|बताओ|साझा करें|शेयर करें|दें|देना)|(ओटीपी|पिन|सीवीवी|पासवर्ड)\s+(किसी (को|से) )?(भी )?(न|ना|मत)\s*(बताएं|बताइए|बताना|साझा करें|शेयर करें|दें|देना)|कभी\s+(भी\s+)?(ओटीपी|पिन|पासवर्ड)\s+(नहीं|ना)\s+(माँगता|मांगता|माँगते|मांगते|पूछता|पूछते)', caseSensitive: false);

  static AnalysisResult analyze(String input, {required String language}) {
    final text = input.trim();
    final isHindi = language == 'हिन्दी';

    // Match against a copy where every whitespace character (including OCR line
    // breaks) is a plain space and safety-advice phrases are blanked out. Both
    // changes keep the length identical, so match positions still point into
    // the original text when we cut evidence snippets.
    var scan = text.replaceAll(RegExp(r'\s'), ' ');
    scan = scan.replaceAllMapped(_safetyAdvice, (m) => ' ' * m.group(0)!.length);

    final foundRules = <_Rule>[];
    final evidence = <String>[];
    final reasons = <String>[];
    var score = 0;

    for (final rule in [..._rules, ..._redFlags]) {
      final match = rule.pattern.firstMatch(scan);
      if (match == null) continue;
      foundRules.add(rule);
      score += rule.weight;
      final snippet = _contextSnippet(text, match.start, match.end);
      if (snippet.isNotEmpty && !evidence.contains(snippet)) evidence.add(snippet);
      final reason = isHindi ? rule.reasonHindi : rule.reasonEnglish;
      if (!reasons.contains(reason)) reasons.add(reason);
    }

    // Authority claim + (money demand or pressure) is the classic digital-arrest
    // pattern, so it counts for more than the parts.
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
    String? categoryEnglish;
    if (categoryRules.isEmpty) {
      category = score >= 2
          ? (isHindi ? 'चेतावनी संकेत मिले' : 'Warning signs detected')
          : (isHindi ? 'सामान्य जाँच' : 'General check');
    } else if (categoryRules.length > 1) {
      category = isHindi ? 'कई प्रकार के चेतावनी संकेत' : 'Multiple warning patterns';
    } else {
      categoryEnglish = categoryRules.first.category;
      category = isHindi ? _hindiCategory(categoryEnglish) : categoryEnglish;
    }

    final tip = categoryEnglish == null ? null : _categoryTip(categoryEnglish, isHindi);
    final nextSteps = _nextSteps(riskKey, tip, isHindi);

    if (reasons.isEmpty) {
      reasons.add(isHindi
          ? 'इस सरल जाँच में कोई स्पष्ट ज्ञात चेतावनी पैटर्न नहीं मिला।'
          : 'This basic check did not find an obvious known warning pattern.');
    }

    var summary = _summaryFor(riskKey, isHindi);
    if (tip != null && riskKey != 'low_indicators') summary = '$summary $tip';

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

  static String _summaryFor(String riskKey, bool isHindi) {
    if (isHindi) {
      return riskKey == 'high'
          ? 'इस संदेश में कई गंभीर चेतावनी संकेत हैं। अभी पैसे न भेजें और निजी जानकारी साझा न करें। स्वतंत्र रूप से जाँच करें।'
          : riskKey == 'review'
              ? 'कुछ चेतावनी संकेत मिले हैं। कोई कदम उठाने से पहले संदेश की स्वतंत्र रूप से जाँच करें।'
              : 'इस सरल जाँच में कम चेतावनी संकेत मिले। इसका अर्थ यह नहीं है कि संदेश सुरक्षित है; स्वतंत्र रूप से सत्यापन करें।';
    }
    return riskKey == 'high'
        ? 'This message has several serious warning signs. Do not send money or share private information. Verify independently.'
        : riskKey == 'review'
            ? 'Some warning signs were found. Verify the message independently before taking action.'
            : 'This basic check found fewer warning signs. That does not mean the message is safe; verify independently.';
  }

  /// Returns [result] with a different risk level and the matching generic advice.
  /// Used when the optional on-device AI model raises the alert.
  static AnalysisResult withRisk(AnalysisResult result, String riskKey) {
    if (riskKey == result.riskKey) return result;
    final isHindi = result.language == 'हिन्दी';
    return result.copyWith(
      riskKey: riskKey,
      nextSteps: _nextSteps(riskKey, null, isHindi),
      spokenSummary: _summaryFor(riskKey, isHindi),
    );
  }

  static List<String> _nextSteps(String riskKey, String? tip, bool isHindi) {
    if (riskKey == 'low_indicators') {
      return isHindi
          ? [
              'इस जाँच में कोई स्पष्ट चेतावनी पैटर्न नहीं मिला, पर इसका मतलब यह नहीं कि संदेश सुरक्षित है।',
              'अनचाहे संदेश के कहने पर पैसे न भेजें और ओटीपी, पिन या पासवर्ड साझा न करें।',
              'शक हो तो किसी भरोसेमंद व्यक्ति से पूछ लें।',
            ]
          : [
              'No obvious warning pattern was found, but that does not mean the message is safe.',
              'Do not send money or share an OTP, PIN, or password because of a message you were not expecting.',
              'If you are unsure, ask someone you trust.',
            ];
    }
    final steps = isHindi
        ? <String>[
            'पैसे ट्रांसफर न करें और ओटीपी, पिन या पासवर्ड साझा न करें।',
            tip ?? 'दबाव डालने वाले कॉल या चैट को रोकें; किसी धमकी को तुरंत सच न मानें।',
            'आधिकारिक ऐप, कार्ड या वेबसाइट पर दिए नंबर से स्वतंत्र रूप से सत्यापन करें।',
            'शक बना रहे तो किसी भरोसेमंद व्यक्ति से बात करें।',
          ]
        : <String>[
            'Do not transfer money or share an OTP, PIN, password, or banking details.',
            tip ?? 'End a pressured call or chat. Do not treat a threat as proof that the caller is genuine.',
            'Verify independently using a number from the official app, card, or website—not one supplied in the message.',
            'If you are unsure, speak to someone you trust before taking action.',
          ];
    if (riskKey == 'high') {
      steps.add(isHindi
          ? 'अगर आप पैसे भेज चुके हैं या जानकारी दे चुके हैं, तो तुरंत अपने बैंक को बताएँ और 1930 पर कॉल करें या cybercrime.gov.in पर शिकायत करें।'
          : 'If you have already paid or shared details, tell your bank right away and report it on 1930 or at cybercrime.gov.in.');
    }
    return steps;
  }

  static String? _categoryTip(String englishCategory, bool isHindi) {
    switch (englishCategory) {
      case 'Digital arrest / authority impersonation':
        return isHindi
            ? 'असली पुलिस, सीबीआई, ईडी या अदालत फ़ोन या वीडियो कॉल पर गिरफ्तारी नहीं करती और पैसे नहीं माँगती। कॉल काट दें और खुद 112 या नज़दीकी थाने से संपर्क करें।'
            : 'Real police, CBI, ED or courts never arrest anyone or ask for money over a phone or video call. Hang up and contact 112 or your local police station yourself.';
      case 'Bank / KYC / OTP':
        return isHindi
            ? 'बैंक आपसे ओटीपी, पिन या सीवीवी कभी नहीं माँगता। अपने बैंक का आधिकारिक ऐप खोलें या कार्ड पर छपे नंबर पर कॉल करें।'
            : 'A bank never asks for your OTP, PIN or CVV. Open your bank\'s own app or call the number printed on your card.';
      case 'Account restriction / support impersonation':
        return isHindi
            ? 'संदेश में दिए नंबर पर कॉल न करें। अपना खाता खुद आधिकारिक ऐप या वेबसाइट पर जाकर जाँचें।'
            : 'Do not call the number given in the message. Open the official app or website yourself to check your account.';
      case 'UPI / payment request':
        return isHindi
            ? 'पैसे पाने के लिए यूपीआई पिन डालने की ज़रूरत नहीं होती। अनजान कलेक्ट रिक्वेस्ट रद्द करें और पैसे पाने के नाम पर क्यूआर कोड स्कैन न करें।'
            : 'You never need to enter a UPI PIN to receive money. Decline unknown collect requests and do not scan a QR code to "receive" money.';
      case 'Courier / parcel impersonation':
        return isHindi
            ? 'कूरियर या कस्टम विभाग कॉल या मैसेज पर शुल्क नहीं माँगता। ट्रैकिंग नंबर कूरियर की आधिकारिक वेबसाइट पर खुद जाँचें।'
            : 'Couriers and customs do not ask for fees by call or message. Check the tracking number on the courier\'s official website yourself.';
      case 'Job / investment offer':
        return isHindi
            ? 'असली नौकरी देने वाले भर्ती के लिए पैसे नहीं लेते और कोई निवेश मुनाफ़े की गारंटी नहीं देता। कमाई के लिए पैसे न भरें।'
            : 'Genuine employers do not charge a fee to hire you, and no investment can guarantee returns. Do not pay in order to earn.';
      default:
        return null;
    }
  }

  static String _hindiCategory(String english) {
    switch (english) {
      case 'Digital arrest / authority impersonation': return 'डिजिटल अरेस्ट / अधिकारी बनकर धोखाधड़ी';
      case 'Bank / KYC / OTP': return 'बैंक / केवाईसी / ओटीपी';
      case 'Account restriction / support impersonation': return 'खाता बंद होने / सपोर्ट बनकर धोखाधड़ी';
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
