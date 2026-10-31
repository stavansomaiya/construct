/// The app stores the chosen language as the string shown on the language buttons.
const String kEnglish = 'English';
const String kHindi = 'हिन्दी';

bool isHindi(String language) => language == kHindi;

/// Tiny translation helper: pick the English or Hindi text for [language].
String tr(String language, String en, String hi) => language == kHindi ? hi : en;
