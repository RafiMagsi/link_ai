import 'package:flutter/material.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../../core/widgets/app_loader.dart';

class CommentComposerBar extends StatelessWidget {
  const CommentComposerBar({
    super.key,
    required this.controller,
    required this.maxChars,
    required this.onSend,
    this.isSending = false,
  });

  final TextEditingController controller;
  final int maxChars;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: colors.border.withValues(alpha: 0.75)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.55),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: maxChars,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    counterText: '',
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filled(
                onPressed: isSending ? null : onSend,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: colorScheme.onSurfaceVariant,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const CircleBorder(),
                ),
                icon: isSending
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: AppLoader(size: 18, strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
