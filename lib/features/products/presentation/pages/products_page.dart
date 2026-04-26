import 'package:flutter/material.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  static const products = [
    _ProductUi(
      name: 'AI Sales Agent',
      tagline: 'Automated follow-up assistant for small businesses',
      category: 'AI Sales',
      stage: 'MVP',
    ),
    _ProductUi(
      name: 'VoicePost AI',
      tagline: 'Turn podcast audio into social content',
      category: 'Content AI',
      stage: 'Prototype',
    ),
    _ProductUi(
      name: 'PromptFlow Kit',
      tagline: 'Reusable prompt workflows for teams',
      category: 'Prompt Engineering',
      stage: 'Idea',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final product = products[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: const Icon(Icons.auto_awesome),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.tagline,
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(label: Text(product.category)),
                            Chip(label: Text(product.stage)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductUi {
  final String name;
  final String tagline;
  final String category;
  final String stage;

  const _ProductUi({
    required this.name,
    required this.tagline,
    required this.category,
    required this.stage,
  });
}
