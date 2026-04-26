import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/presentation/providers/profile_providers.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesState = ref.watch(publicProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkAI'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: profilesState.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('No AI builders yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final profile = profiles[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  title: Text(
                    profile.name.isEmpty ? 'Unnamed Builder' : profile.name,
                  ),
                  subtitle: Text(
                    profile.role.isEmpty
                        ? 'AI Builder'
                        : '${profile.role}\n${profile.building}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/profiles/${profile.uid}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load profiles.')),
      ),
    );
  }
}
