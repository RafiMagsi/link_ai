import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const categories = [
    'AI SaaS',
    'AI Agents',
    'Automation',
    'Prompt Engineering',
    'AI Video',
    'AI Sales',
    'AI Coding',
    'AI Design',
    'AI Education',
    'No-Code AI',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Discover AI builders by category',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories.map((category) {
              return ActionChip(label: Text(category), onPressed: () {});
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'People looking for help',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            title: 'Need beta users',
            subtitle: 'AI founders testing MVPs',
            icon: Icons.rocket_launch_outlined,
          ),
          _ExploreCard(
            title: 'Need collaborators',
            subtitle: 'Builders looking for designers, devs, and marketers',
            icon: Icons.groups_outlined,
          ),
          _ExploreCard(
            title: 'Need feedback',
            subtitle: 'Projects waiting for honest product review',
            icon: Icons.rate_review_outlined,
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
