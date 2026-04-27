abstract class HashtagUtils {
  static final RegExp _regex = RegExp(
    r'(^|[^A-Za-z0-9_])#([A-Za-z0-9_]{1,30})',
  );

  static List<String> extractNormalized(String text, {int max = 20}) {
    final matches = _regex.allMatches(text);
    final out = <String>[];
    final seen = <String>{};

    for (final m in matches) {
      final tag = (m.group(2) ?? '').toLowerCase();
      if (tag.isEmpty) continue;
      if (seen.add(tag)) {
        out.add(tag);
        if (out.length >= max) break;
      }
    }

    return out;
  }

  static bool isHashtagChar(int codeUnit) {
    final c = codeUnit;
    return (c >= 48 && c <= 57) || // 0-9
        (c >= 65 && c <= 90) || // A-Z
        (c >= 97 && c <= 122) || // a-z
        c == 95; // _
  }
}
