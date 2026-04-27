import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_sizes.dart';

class HashtagText extends StatelessWidget {
  const HashtagText({
    super.key,
    required this.text,
    this.style,
    this.hashtagStyle,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? hashtagStyle;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final passedStyle = style ?? DefaultTextStyle.of(context).style;
    final baseStyle = passedStyle.color == null
        ? passedStyle.copyWith(color: Theme.of(context).colorScheme.onSurface)
        : passedStyle;
    final tagStyle =
        hashtagStyle ??
        baseStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        );

    final spans = <InlineSpan>[];
    final regex = RegExp(r'(^|[^A-Za-z0-9_])#([A-Za-z0-9_]{1,30})');

    var last = 0;
    for (final match in regex.allMatches(text)) {
      final fullStart = match.start;
      final fullEnd = match.end;
      final prefixLen = (match.group(1) ?? '').length;

      final hashtagStart = fullStart + prefixLen;
      final hashtagEnd = fullEnd;

      if (hashtagStart > last) {
        spans.add(
          TextSpan(text: text.substring(last, hashtagStart), style: baseStyle),
        );
      }

      final rawTag = match.group(2) ?? '';
      final normalized = rawTag.toLowerCase();

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.sm),
            onTap: () => context.push('/hashtags/$normalized'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Text('#$rawTag', style: tagStyle),
            ),
          ),
        ),
      );

      last = hashtagEnd;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }

    // If no hashtags matched, just render plain text.
    if (spans.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines);
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.clip,
      text: TextSpan(children: spans, style: baseStyle),
    );
  }
}
