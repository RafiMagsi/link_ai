import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_model.dart';
import '../providers/product_providers.dart';

class EditProductPage extends ConsumerStatefulWidget {
  const EditProductPage({
    super.key,
    required this.product,
  });

  final ProductModel product;

  @override
  ConsumerState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends ConsumerState<EditProductPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _tagsController;
  late final TextEditingController _pricingController;
  late final TextEditingController _websiteUrlController;
  late final TextEditingController _demoUrlController;
  late final TextEditingController _githubUrlController;
  late final TextEditingController _platformsController;
  late final TextEditingController _versionController;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _nameController = TextEditingController(text: product.name);
    _taglineController = TextEditingController(text: product.tagline);
    _descriptionController = TextEditingController(text: product.description);
    _categoryController = TextEditingController(text: product.category);
    _tagsController = TextEditingController(text: product.tags.join(', '));
    _pricingController = TextEditingController(text: product.pricing);
    _websiteUrlController = TextEditingController(text: product.websiteUrl);
    _demoUrlController = TextEditingController(text: product.demoUrl);
    _githubUrlController = TextEditingController(text: product.githubUrl);
    _platformsController =
        TextEditingController(text: product.platforms.join(', '));
    _versionController = TextEditingController(text: product.version);
  }

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

  Future<void> _save() async {
    final updated = widget.product.copyWith(
      name: _nameController.text.trim(),
      tagline: _taglineController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      tags: _splitCsv(_tagsController.text),
      pricing: _pricingController.text.trim(),
      websiteUrl: _websiteUrlController.text.trim(),
      demoUrl: _demoUrlController.text.trim(),
      githubUrl: _githubUrlController.text.trim(),
      platforms: _splitCsv(_platformsController.text),
      version: _versionController.text.trim(),
    );

    await ref.read(productControllerProvider.notifier).updateProduct(updated);

    final state = ref.read(productControllerProvider);

    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update product.')),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(productControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: controllerState.isLoading ? null : _save,
              child: const Text('Save'),
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
          _Field(controller: _tagsController, label: 'Tags'),
          _Field(controller: _pricingController, label: 'Pricing'),
          _Field(controller: _websiteUrlController, label: 'Website URL'),
          _Field(controller: _demoUrlController, label: 'Demo URL'),
          _Field(controller: _githubUrlController, label: 'GitHub URL'),
          _Field(controller: _platformsController, label: 'Platforms'),
          _Field(controller: _versionController, label: 'Version'),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
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
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}