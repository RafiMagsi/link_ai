import 'package:flutter/material.dart';

import '../../../data/models/post_model.dart';

class SnowPostAskBody extends StatelessWidget {
  const SnowPostAskBody({
    super.key,
    required this.post,
  });

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final askMeta = post.askMeta;
    if (askMeta == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          askMeta.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        if (askMeta.topics.isNotEmpty)
          Wrap(
            spacing: 6,
            children: askMeta.topics
                .map(
                  (topic) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      topic,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            // TODO: Expand replies in place
          },
          child: Text(
            '${askMeta.answerCount} answered →',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF378ADD),
            ),
          ),
        ),
      ],
    );
  }
}
