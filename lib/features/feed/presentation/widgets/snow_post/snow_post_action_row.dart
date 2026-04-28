import 'package:flutter/material.dart';

import '../../../data/models/post_model.dart';

class SnowPostActionRow extends StatelessWidget {
  const SnowPostActionRow({
    super.key,
    required this.post,
    required this.onCommentTap,
  });

  final PostModel post;
  final VoidCallback onCommentTap;

  List<_SnowActionData> _actions(PostType type) {
    return switch (type) {
      PostType.thought => const [
          _SnowActionData(
            icon: Icons.auto_awesome_outlined,
            label: 'React',
            isPrimary: true,
          ),
          _SnowActionData(
            icon: Icons.mode_comment_outlined,
            label: 'Reply',
          ),
          _SnowActionData(
            icon: Icons.bookmark_border_rounded,
            label: 'Save',
          ),
        ],
      PostType.ship => const [
          _SnowActionData(
            icon: Icons.check_circle_outline_rounded,
            label: 'Use this',
            isPrimary: true,
          ),
          _SnowActionData(
            icon: Icons.schedule_outlined,
            label: 'Beta in',
          ),
          _SnowActionData(
            icon: Icons.bookmark_border_rounded,
            label: 'Save',
          ),
        ],
      PostType.ask => const [
          _SnowActionData(
            icon: Icons.handshake_outlined,
            label: 'Help',
            isPrimary: true,
          ),
          _SnowActionData(
            icon: Icons.mode_comment_outlined,
            label: 'Reply',
          ),
          _SnowActionData(
            icon: Icons.bookmark_border_rounded,
            label: 'Save',
          ),
        ],
    };
  }

  Color _accentColor(PostType type) {
    return switch (type) {
      PostType.thought => const Color(0xFF7A756D),
      PostType.ship => const Color(0xFF4F8A12),
      PostType.ask => const Color(0xFF1D74C8),
    };
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions(post.postType);
    final accent = _accentColor(post.postType);
    final mutedColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.86);

    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Row(
        children: List.generate(actions.length, (index) {
          final action = actions[index];
          final color = action.isPrimary ? accent : mutedColor;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: index == 1 ? onCommentTap : () {},
                borderRadius: BorderRadius.circular(999),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action.icon,
                            size: 17,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            action.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: action.isPrimary
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SnowActionData {
  const _SnowActionData({
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
}
