import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../data/models/message_model.dart';
import 'package:link_ai/features/explore/presentation/widgets/shadow_style.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isSender,
  });

  final MessageModel message;
  final bool isSender;

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSender
                      ? [
                          const Color.fromARGB(255, 220, 233, 251), // light blue top
                          const Color.fromARGB(255, 233, 229, 252), // light violet middle
                          const Color.fromARGB(255, 252, 226, 241), // light pink bottom
                        ]
                      : [
                          Theme.of(context).colorScheme.surface,
                          Color.alphaBlend(
                            const Color(0xFFEFF6FF).withValues(alpha: 0.58),
                            Theme.of(context).colorScheme.surface,
                          ),
                          Color.alphaBlend(
                            const Color(0xFFF5F3FF).withValues(alpha: 0.42),
                            Theme.of(context).colorScheme.surface,
                          ),
                        ],
                  stops: const [0.0, 0.52, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isSender ? 18 : 6),
                  bottomRight: Radius.circular(isSender ? 6 : 18),
                ),
                border: Border.all(
                  color: isSender
                      ? const Color(0xFFA78BFA).withValues(alpha: 0.16)
                      : const Color(0xFF60A5FA).withValues(alpha: 0.10),
                  width: 0.7,
                ),
                boxShadow: ShadowStyle.messageAura(
                  color: isSender
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFF60A5FA),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.22,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAtClient ?? message.createdAt),
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
