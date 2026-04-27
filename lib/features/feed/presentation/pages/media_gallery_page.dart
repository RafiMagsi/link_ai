import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

class MediaGalleryPage extends StatefulWidget {
  const MediaGalleryPage({
    super.key,
    required this.mediaUrls,
    required this.initialIndex,
    required this.heroTagPrefix,
  });

  final List<String> mediaUrls;
  final int initialIndex;
  final String heroTagPrefix;

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.mediaUrls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: scheme.onError,
        title: Text('${_index + 1}/${widget.mediaUrls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) {
          final url = widget.mediaUrls[index];
          final tag = '${widget.heroTagPrefix}$index';

          return Center(
            child: Hero(
              tag: tag,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 44,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: AppSizes.md),
                          const Text(
                            'Unable to load media',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
