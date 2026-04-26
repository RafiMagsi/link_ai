import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/feed_post_ui_model.dart';
import '../widgets/feed_post_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  static const _posts = [
    FeedPostUiModel(
      id: '1',
      authorName: 'Rafi Khan',
      authorRole: 'Flutter / Laravel / AI Builder',
      authorAvatarUrl: null,
      timestampText: '12m',
      text:
          'Building LinkAI today — a focused networking app for people working in AI. The goal is simple: show what you are building, what you need, and who you want to meet.',
      mediaUrls: [],
      likesCount: 18,
      repostsCount: 4,
      commentsCount: 7,
      savesCount: 5,
    ),
    FeedPostUiModel(
      id: '2',
      authorName: 'Sara Ahmed',
      authorRole: 'AI Product Designer',
      authorAvatarUrl: null,
      timestampText: '36m',
      text:
          'Looking for AI founders who need product feedback. I can help with onboarding, app structure, and UX clarity.',
      mediaUrls: [
        'https://images.unsplash.com/photo-1551434678-e076c223a692?w=1200',
      ],
      likesCount: 41,
      repostsCount: 8,
      commentsCount: 11,
      savesCount: 13,
    ),
    FeedPostUiModel(
      id: '3',
      authorName: 'Omar Malik',
      authorRole: 'AI Automation Builder',
      authorAvatarUrl: null,
      timestampText: '1h',
      text:
          'I am testing an AI workflow that turns customer emails into CRM tasks, follow-ups, and quote drafts. Need beta testers from agencies.',
      mediaUrls: [
        'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=1200',
        'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=1200',
      ],
      likesCount: 63,
      repostsCount: 12,
      commentsCount: 19,
      savesCount: 22,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/posts/create'),
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.separated(
          itemCount: _posts.length + 1,
          separatorBuilder: (_, __) {
            return const Divider(
              height: 1,
              thickness: 0.7,
              color: Color(0xFF1E293B),
            );
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _FeedComposerEntry();
            }

            return FeedPostCard(post: _posts[index - 1]);
          },
        ),
      ),
    );
  }
}

class _FeedComposerEntry extends StatelessWidget {
  const _FeedComposerEntry();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/posts/create'),
      child: Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Text(
                  'What are you building in AI?',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}