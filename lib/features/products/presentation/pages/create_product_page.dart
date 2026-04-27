import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/errors/error_handler.dart';
import '../providers/product_providers.dart';

class CreateProductPage extends ConsumerStatefulWidget {
  const CreateProductPage({super.key});

  @override
  ConsumerState<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends ConsumerState<CreateProductPage> {
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final _pricingController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  final _demoUrlController = TextEditingController();
  final _githubUrlController = TextEditingController();
  final _platformsController = TextEditingController();
  final _versionController = TextEditingController(text: '1.0.0');

  final _imagePicker = ImagePicker();
  final List<File> _screenshots = [];

  static const _maxScreenshots = 6;

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _pricingController.dispose();
    _websiteUrlController.dispose();
    _demoUrlController.dispose();
    _githubUrlController.dispose();
    _platformsController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _pickScreenshots() async {
    if (_screenshots.length >= _maxScreenshots) {
      _showMessage('Maximum $_maxScreenshots screenshots allowed.');
      return;
    }

    final remaining = _maxScreenshots - _screenshots.length;

    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (images.isEmpty) return; // User cancelled

      if (!mounted) return;

      setState(() {
        _screenshots.addAll(
          images.take(remaining).map((image) => File(image.path)),
        );
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        'Failed to pick images: ${ErrorHandler.getUserFriendlyMessage(e)}',
      );
    }
  }

  void _removeScreenshot(int index) {
    setState(() {
      _screenshots.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final tagline = _taglineController.text.trim();
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();

    // Form validation
    if (name.isEmpty ||
        tagline.isEmpty ||
        description.isEmpty ||
        category.isEmpty) {
      _showMessage('Name, tagline, description, and category are required.');
      return;
    }

    try {
      await ref
          .read(productControllerProvider.notifier)
          .createProduct(
            name: name,
            tagline: tagline,
            description: description,
            category: category,
            tags: _splitCsv(_tagsController.text),
            pricing: _pricingController.text.trim(),
            websiteUrl: _websiteUrlController.text.trim(),
            demoUrl: _demoUrlController.text.trim(),
            githubUrl: _githubUrlController.text.trim(),
            platforms: _splitCsv(_platformsController.text),
            version: _versionController.text.trim(),
            screenshotFiles: _screenshots,
          );

      final state = ref.read(productControllerProvider);

      if (!mounted) return;

      if (state.hasError) {
        _showMessage(
          'Unable to create product: ${ErrorHandler.getUserFriendlyMessage(state.error)}',
        );
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        'Failed to create product: ${ErrorHandler.getUserFriendlyMessage(e)}',
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
    final controllerState = ref.watch(productControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add AI Product'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: controllerState.isLoading ? null : _submit,
              child: controllerState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: AppLoader(size: 20, strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Field(controller: _nameController, label: 'Product Name'),
          _Field(controller: _taglineController, label: 'Tagline'),
          _Field(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 5,
          ),
          _Field(controller: _categoryController, label: 'Category'),
          _Field(
            controller: _tagsController,
            label: 'Tags',
            hint: 'OpenAI, Automation, SaaS',
          ),
          _Field(controller: _pricingController, label: 'Pricing'),
          _Field(controller: _websiteUrlController, label: 'Website URL'),
          _Field(controller: _demoUrlController, label: 'Demo URL'),
          _Field(controller: _githubUrlController, label: 'GitHub URL'),
          _Field(
            controller: _platformsController,
            label: 'Platforms',
            hint: 'Web, iOS, Android',
          ),
          _Field(controller: _versionController, label: 'Version'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controllerState.isLoading ? null : _pickScreenshots,
            icon: const Icon(Icons.image),
            label: const Text('Add Screenshots'),
          ),
          const SizedBox(height: 12),
          if (_screenshots.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _screenshots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      child: Image.file(_screenshots[index], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black.withValues(alpha: 0.65),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _removeScreenshot(index),
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onError,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
