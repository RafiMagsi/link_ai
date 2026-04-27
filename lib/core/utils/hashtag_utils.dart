abstract class HashtagUtils {
  static late final RegExp _regex;
  static bool _regexInitialized = false;

  static RegExp _getRegex() {
    if (!_regexInitialized) {
      try {
        _regex = RegExp(
          r'(^|[^A-Za-z0-9_])#([A-Za-z0-9_]{1,30})',
        );
        _regexInitialized = true;
      } catch (e) {
        print('Error initializing regex: $e');
        // Return a more lenient regex as fallback
        _regex = RegExp(r'#(\w+)');
        _regexInitialized = true;
      }
    }
    return _regex;
  }

  /// Extracts and normalizes hashtags from text.
  /// Returns empty list on error instead of throwing.
  static List<String> extractNormalized(String text, {int max = 20}) {
    try {
      // Validate inputs
      if (text.isEmpty || max <= 0) {
        return [];
      }

      max = max.clamp(1, 100); // Limit max to reasonable range

      final regex = _getRegex();
      final matches = regex.allMatches(text);
      final out = <String>[];
      final seen = <String>{};

      for (final m in matches) {
        try {
          final tag = (m.group(2) ?? '').toLowerCase().trim();
          if (tag.isEmpty || tag.length > 30) continue;
          if (seen.add(tag)) {
            out.add(tag);
            if (out.length >= max) break;
          }
        } catch (e) {
          print('Error processing hashtag match: $e');
          continue;
        }
      }

      return out;
    } catch (e) {
      print('Error extracting hashtags: $e');
      return [];
    }
  }

  /// Safely checks if a character code is valid for hashtags.
  /// Returns false on error.
  static bool isHashtagChar(int codeUnit) {
    try {
      // Validate input range (Unicode code units should be non-negative)
      if (codeUnit < 0 || codeUnit > 0x10FFFF) {
        return false;
      }

      final c = codeUnit;
      return (c >= 48 && c <= 57) || // 0-9
          (c >= 65 && c <= 90) || // A-Z
          (c >= 97 && c <= 122) || // a-z
          c == 95; // _
    } catch (e) {
      print('Error checking hashtag char: $e');
      return false;
    }
  }

  /// Validates if a string is a valid hashtag format.
  static bool isValidHashtag(String tag) {
    try {
      if (tag.isEmpty || tag.length > 30) return false;
      if (!tag.startsWith('#')) return false;
      final content = tag.substring(1);
      return content.isNotEmpty &&
          content.runes.every((rune) => isHashtagChar(rune));
    } catch (e) {
      print('Error validating hashtag: $e');
      return false;
    }
  }
}
