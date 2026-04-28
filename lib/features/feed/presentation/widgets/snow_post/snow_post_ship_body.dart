import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/post_model.dart';

class SnowPostShipBody extends StatelessWidget {
  const SnowPostShipBody({
    super.key,
    required this.post,
  });

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final shipMeta = post.shipMeta;
    if (shipMeta == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shipMeta.projectName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          shipMeta.tagline,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        if (shipMeta.demoUrl?.isNotEmpty ?? false)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3DE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: shipMeta.demoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: Icon(Icons.image, color: Color(0xFF639922)),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Color(0xFF639922)),
                ),
              ),
            ),
          ),
        if (shipMeta.demoUrl?.isNotEmpty ?? false) const SizedBox(height: 10),
        if (shipMeta.ctaUrl?.isNotEmpty ?? false)
          GestureDetector(
            onTap: () async {
              if (await canLaunchUrl(Uri.parse(shipMeta.ctaUrl!))) {
                await launchUrl(Uri.parse(shipMeta.ctaUrl!));
              }
            },
            child: Text(
              'Try it →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF639922),
              ),
            ),
          ),
      ],
    );
  }
}
