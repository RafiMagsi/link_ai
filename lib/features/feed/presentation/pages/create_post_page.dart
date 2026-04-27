import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/app_limits_provider.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/post_providers.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<File> _selectedMedia = [];

  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final limits = ref.read(appLimitsProvider);

    if (_selectedMedia.length >= limits.postMaxMediaItems) {
      _showMessage('Maximum ${limits.postMaxMediaItems} media items allowed.');
      return;
    }

    final remaining = limits.postMaxMediaItems - _selectedMedia.length;

    final pickedImages = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (pickedImages.isEmpty) return;

    final selected = <File>[];
    for (final image in pickedImages.take(remaining)) {
      final file = File(image.path);
      final sizeBytes = await file.length();

      if (sizeBytes > limits.imageMaxBytes) {
        _showMessage(
          'Image is larger than ${_bytesToMb(limits.imageMaxBytes)} MB.',
        );
        continue;
      }

      selected.add(file);
    }

    setState(() {
      _selectedMedia.addAll(selected);
    });
  }

  Future<void> _pickVideo() async {
    final limits = ref.read(appLimitsProvider);

    if (_selectedMedia.length >= limits.postMaxMediaItems) {
      _showMessage('Maximum ${limits.postMaxMediaItems} media items allowed.');
      return;
    }

    final pickedVideo = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(seconds: limits.videoMaxDurationSeconds),
    );

    if (pickedVideo == null) return;

    final file = File(pickedVideo.path);
    final sizeBytes = await file.length();

    if (sizeBytes > limits.videoMaxBytes) {
      _showMessage(
        'Video is larger than ${_bytesToMb(limits.videoMaxBytes)} MB.',
      );
      return;
    }

    setState(() {
      _selectedMedia.add(file);
    });
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final limits = ref.read(appLimitsProvider);
    final text = _textController.text.trim();

    if (text.isEmpty && _selectedMedia.isEmpty) {
      _showMessage('Write something or add media.');
      return;
    }

    if (text.length > limits.postMaxChars) {
      _showMessage('Post text is too long.');
      return;
    }

    final hasVideo = _selectedMedia.any((file) => _isVideoPath(file.path));
    if (hasVideo) {
      _showMessage(
        'Video posts are not supported yet. Remove the video to post.',
      );
      return;
    }

    final imageFiles = _selectedMedia;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    await ref
        .read(postControllerProvider.notifier)
        .createPost(text: text, imageFiles: imageFiles);

    final state = ref.read(postControllerProvider);

    if (!mounted) return;

    setState(() {
      _isUploading = false;
      _uploadProgress = 0;
    });

    if (state.hasError) {
      _showMessage('Unable to create post.');
      return;
    }

    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textLength = _textController.text.length;
    final limits = ref.watch(appLimitsProvider);
    final remaining = limits.postMaxChars - textLength;
    final isOverLimit = remaining < 0;
    final colors = context.appColors;
    final myProfile = ref.watch(myProfileProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isUploading || isOverLimit ? null : _submit,
              child: const Text('Post'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.lg),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppUserAvatar(
                        avatarUrl: myProfile?.avatarUrl,
                        radius: 22,
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          minLines: 5,
                          maxLength: limits.postMaxChars,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'What are you building in AI?',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          style: const TextStyle(fontSize: 18, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedMedia.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.lg),
                    _SelectedMediaGrid(
                      files: _selectedMedia,
                      onRemove: _removeMedia,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                10,
                AppSizes.lg,
                14,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isUploading ? null : _pickImages,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  IconButton(
                    onPressed: _isUploading ? null : _pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                  ),
                  const Spacer(),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      color: isOverLimit
                          ? Theme.of(context).colorScheme.error
                          : colors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _bytesToMb(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb == mb.roundToDouble()) return mb.toStringAsFixed(0);
  return mb.toStringAsFixed(1);
}

bool _isVideoPath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.avi');
}

class _SelectedMediaGrid extends StatelessWidget {
  const _SelectedMediaGrid({required this.files, required this.onRemove});

  final List<File> files;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (files.length == 1) {
      return _SelectedMediaTile(
        file: files.first,
        index: 0,
        onRemove: onRemove,
        height: 260,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return _SelectedMediaTile(
          file: files[index],
          index: index,
          onRemove: onRemove,
        );
      },
    );
  }
}

class _SelectedMediaTile extends StatelessWidget {
  const _SelectedMediaTile({
    required this.file,
    required this.index,
    required this.onRemove,
    this.height,
  });

  final File file;
  final int index;
  final void Function(int index) onRemove;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoPath(file.path);
    final colors = context.appColors;

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo)
            Container(
              color: colors.surfaceMuted,
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 56,
                  color: colors.mutedText,
                ),
              ),
            )
          else
            Image.file(file, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black.withValues(alpha: 0.65),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => onRemove(index),
                icon: const Icon(Icons.close, size: 17, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
