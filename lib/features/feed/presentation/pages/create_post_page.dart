import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/app_limits.dart';
import '../../../../core/config/app_limits_provider.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../../core/errors/error_handler.dart';
import '../../data/models/post_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/post_providers.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({
    super.key,
    this.showAppBar = true,
    this.compact = false,
  });

  final bool showAppBar;
  final bool compact;

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<File> _selectedMedia = [];
  PostIntent _selectedIntent = PostIntent.general;

  bool _isUploading = false;
  double _uploadProgress = 0;

  bool get _hasAnyContent {
    return _textController.text.trim().isNotEmpty || _selectedMedia.isNotEmpty;
  }

  bool _isValidForSubmit(AppLimits limits) {
    final text = _textController.text.trim();
    if (text.length > limits.postMaxChars) return false;
    if (_selectedMedia.length > limits.postMaxMediaItems) return false;
    if (!_hasAnyContent) return false;

    final hasVideo = _selectedMedia.any((file) => _isVideoPath(file.path));
    if (hasVideo) return false;

    return true;
  }

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

    try {
      final pickedImages = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedImages.isEmpty) return; // User cancelled

      if (!mounted) return;

      final selected = <File>[];
      for (final image in pickedImages.take(remaining)) {
        try {
          final file = File(image.path);
          final sizeBytes = await file.length();

          if (sizeBytes > limits.imageMaxBytes) {
            _showMessage(
              'Image is larger than ${_bytesToMb(limits.imageMaxBytes)} MB.',
            );
            continue;
          }

          selected.add(file);
        } catch (e) {
          if (mounted) {
            _showMessage('Failed to process image: ${ErrorHandler.getUserFriendlyMessage(e)}');
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _selectedMedia.addAll(selected);
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        'Failed to pick images: ${ErrorHandler.getUserFriendlyMessage(e)}',
      );
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final limits = ref.read(appLimitsProvider);
    final text = _textController.text.trim();

    // Validation
    if (!_isValidForSubmit(limits)) {
      if (!_hasAnyContent) {
        _showMessage('Write something or add media.');
        return;
      }
      if (text.length > limits.postMaxChars) {
        _showMessage('Post text is too long.');
        return;
      }
      _showMessage('Unable to post. Remove unsupported media and try again.');
      return;
    }

    final imageFiles = _selectedMedia;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.05;
    });

    // Until we have per-file progress, provide a simple "alive" indicator.
    late final StreamSubscription<int> progressTimer;
    try {
      progressTimer = Stream.periodic(
            const Duration(milliseconds: 220),
            (tick) => tick,
          ).listen((_) {
            if (!mounted || !_isUploading) return;
            setState(() {
              _uploadProgress = (_uploadProgress + 0.07).clamp(0.05, 0.90);
            });
          });

      await ref
          .read(postControllerProvider.notifier)
          .createPost(
            text: text,
            imageFiles: imageFiles,
            postIntent: _selectedIntent,
          );

      await progressTimer.cancel();

      final state = ref.read(postControllerProvider);

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });

      if (state.hasError) {
        _showMessage(
          'Unable to create post: ${ErrorHandler.getUserFriendlyMessage(state.error)}',
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      await progressTimer.cancel();

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });

      _showMessage(
        'Failed to create post: ${ErrorHandler.getUserFriendlyMessage(e)}',
      );
    }
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
    final canSubmit = !_isUploading && _isValidForSubmit(limits);
    final hintText = switch (_selectedIntent) {
      PostIntent.launch => 'What did you launch in AI?',
      PostIntent.feedback => 'What do you want feedback on?',
      PostIntent.hiring => 'Who are you hiring for?',
      PostIntent.cofounder => 'Who are you looking for as a cofounder?',
      PostIntent.question => 'What AI question do you need help with?',
      PostIntent.general => 'What are you building in AI?',
    };

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: widget.showAppBar
            ? AppBar(
              actionsPadding: EdgeInsets.only(top: 6),
                title: const Text('Create Post'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      child: const Text('Post'),
                    ),
                  ),
                ],
              )
            : null,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.sm,
                    AppSizes.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: colors.mutedText),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          'Uploading… ${(_uploadProgress * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    widget.compact ? AppSizes.md : AppSizes.lg,
                    widget.compact ? AppSizes.sm : AppSizes.lg,
                    widget.compact ? AppSizes.md : AppSizes.lg,
                    AppSizes.lg,
                  ),
                  children: [
                  _IntentSelector(
                    selectedIntent: _selectedIntent,
                    onChanged: (intent) {
                      setState(() {
                        _selectedIntent = intent;
                      });
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
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
                          decoration: InputDecoration(
                            hintText: hintText,
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
                  Tooltip(
                    message: 'Video posts coming soon',
                    child: IconButton(
                      onPressed: _isUploading
                          ? null
                          : () {
                              _showMessage('Video posts coming soon.');
                            },
                      icon: const Icon(Icons.videocam_outlined),
                    ),
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
      ),
    );
  }
}

class _IntentSelector extends StatelessWidget {
  const _IntentSelector({
    required this.selectedIntent,
    required this.onChanged,
  });

  final PostIntent selectedIntent;
  final ValueChanged<PostIntent> onChanged;

  static const _options = <(PostIntent intent, String label)>[
    (PostIntent.general, 'General'),
    (PostIntent.launch, 'Launch'),
    (PostIntent.feedback, 'Feedback'),
    (PostIntent.hiring, 'Hiring'),
    (PostIntent.cofounder, 'Cofounder'),
    (PostIntent.question, 'Question'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _options[index];
          return ChoiceChip(
            label: Text(option.$2),
            selected: selectedIntent == option.$1,
            onSelected: (_) => onChanged(option.$1),
            visualDensity: VisualDensity.compact,
          );
        },
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
                icon: Icon(
                  Icons.close,
                  size: 17,
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
