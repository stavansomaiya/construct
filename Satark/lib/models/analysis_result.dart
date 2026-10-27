class AnalysisResult {
  const AnalysisResult({
    required this.originalText,
    required this.language,
    required this.riskKey,
    required this.category,
    required this.score,
    required this.evidence,
    required this.warningSigns,
    required this.nextSteps,
    required this.spokenSummary,
    required this.disclaimer,
  });

  final String originalText;
  final String language;
  final String riskKey; // high, review, low_indicators
  final String category;
  final int score;
  final List<String> evidence;
  final List<String> warningSigns;
  final List<String> nextSteps;
  final String spokenSummary;
  final String disclaimer;

  String get riskLabel {
    switch (riskKey) {
      case 'high':
        return language == 'हिन्दी' ? 'उच्च जोखिम' : 'HIGH RISK';
      case 'review':
        return language == 'हिन्दी' ? 'ध्यान से जाँचें' : 'CHECK CAREFULLY';
      default:
        return language == 'हिन्दी' ? 'कम संकेत मिले' : 'FEWER WARNING SIGNS';
    }
  }

  Map<String, dynamic> toJson() => {
        'originalText': originalText,
        'language': language,
        'riskKey': riskKey,
        'category': category,
        'score': score,
        'evidence': evidence,
        'warningSigns': warningSigns,
        'nextSteps': nextSteps,
        'spokenSummary': spokenSummary,
        'disclaimer': disclaimer,
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        originalText: json['originalText'] as String? ?? '',
        language: json['language'] as String? ?? 'English',
        riskKey: json['riskKey'] as String? ?? 'low_indicators',
        category: json['category'] as String? ?? 'General check',
        score: json['score'] as int? ?? 0,
        evidence: (json['evidence'] as List<dynamic>? ?? const []).cast<String>(),
        warningSigns: (json['warningSigns'] as List<dynamic>? ?? const []).cast<String>(),
        nextSteps: (json['nextSteps'] as List<dynamic>? ?? const []).cast<String>(),
        spokenSummary: json['spokenSummary'] as String? ?? '',
        disclaimer: json['disclaimer'] as String? ?? '',
      );
}
