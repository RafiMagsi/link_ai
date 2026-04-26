import 'package:flutter/material.dart';

import '../../data/models/feed_post_ui_model.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
  });

  final FeedPostUiModel post;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            name: post.authorName,
            avatarUrl: post.authorAvatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PostHeader(post: post),
                const SizedBox(height: 6),
                Text(
                  post.text,
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 15.5,
                    height: 1.35,
                  ),
                ),
                if (post.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _MediaGrid(mediaUrls: post.mediaUrls),
                ],
                const SizedBox(height: 10),
                _ActionRow(post: post),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFF1E293B),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
  });

  final FeedPostUiModel post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            post.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            post.authorRole,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '·',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 6),
        Text(
          post.timestampText,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.mediaUrls,
  });

  final List<String> mediaUrls;

  @override
  Widget build(BuildContext context) {
    final count = mediaUrls.length.clamp(0, 4);

    if (count == 1) {
      return _MediaTile(url: mediaUrls.first, height: 220);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        return _MediaTile(url: mediaUrls[index]);
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.url,
    this.height,
  });

  final String url;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8),
            ),
          );
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.post,
  });

  final FeedPostUiModel post;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          count: post.commentsCount,
          label: 'Comment',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.repeat,
          count: post.repostsCount,
          label: 'Repost',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.favorite_border,
          count: post.likesCount,
          label: 'Like',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.bookmark_border,
          count: post.savesCount,
          label: 'Save',
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.count,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}