import 'package:flutter/material.dart';

import '../../../../../core/widgets/hashtag_text.dart';
import '../../../data/models/post_model.dart';
import '../post/post_media_grid.dart';
import '../../pages/media_gallery_page.dart';

class SnowPostThoughtBody extends StatelessWidget {
  const SnowPostThoughtBody({
    super.key,
    required this.post,
  });

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.text.trim().isNotEmpty)
          HashtagText(
            text: post.text,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        if (post.media.isNotEmpty) ...[
          const SizedBox(height: 12),
          PostMediaGrid(
            mediaUrls: post.media.map((e) => e.url).toList(),
            heroTagPrefix: 'snow_post_${post.id}_media_',
            onTap: (index) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MediaGalleryPage(
                    mediaUrls: post.media.map((e) => e.url).toList(),
                    initialIndex: index,
                    heroTagPrefix: 'snow_post_${post.id}_media_',
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
