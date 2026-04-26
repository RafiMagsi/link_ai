import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  static const int _fallbackMaxLength = 280;
  static const int _maxMediaCount = 4;

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
    if (_selectedMedia.length >= _maxMediaCount) {
      _showMessage('Maximum $_maxMediaCount media items allowed.');
      return;
    }

    final remaining = _maxMediaCount - _selectedMedia.length;

    final pickedImages = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (pickedImages.isEmpty) return;

    final selected = pickedImages
        .take(remaining)
        .map((image) => File(image.path))
        .toList();

    setState(() {
      _selectedMedia.addAll(selected);
    });
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();

    if (text.isEmpty && _selectedMedia.isEmpty) {
      _showMessage('Write something or add media.');
      return;
    }

    if (text.length > _fallbackMaxLength) {
      _showMessage('Post text is too long.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.3;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));

    setState(() {
      _uploadProgress = 0.75;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));

    setState(() {
      _uploadProgress = 1;
      _isUploading = false;
    });

    if (!mounted) return;

    _showMessage('Post composer UI ready. Firestore submit comes next.');
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textLength = _textController.text.length;
    final remaining = _fallbackMaxLength - textLength;
    final isOverLimit = remaining < 0;

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
            if (_isUploading)
              LinearProgressIndicator(value: _uploadProgress),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF1E293B),
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          minLines: 5,
                          maxLength: _fallbackMaxLength,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'What are you building in AI?',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedMedia.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SelectedMediaGrid(
                      files: _selectedMedia,
                      onRemove: _removeMedia,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF1E293B)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isUploading ? null : _pickImages,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  IconButton(
                    onPressed: _isUploading
                        ? null
                        : () {
                            _showMessage('Video picker comes after image flow.');
                          },
                    icon: const Icon(Icons.videocam_outlined),
                  ),
                  const Spacer(),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      color: isOverLimit
                          ? Colors.redAccent
                          : const Color(0xFF94A3B8),
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

class _SelectedMediaGrid extends StatelessWidget {
  const _SelectedMediaGrid({
    required this.files,
    required this.onRemove,
  });

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
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            file,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black.withOpacity(0.65),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => onRemove(index),
                icon: const Icon(
                  Icons.close,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}