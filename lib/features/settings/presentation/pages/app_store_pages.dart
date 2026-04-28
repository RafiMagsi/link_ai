import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentPage(
      title: 'Privacy Policy',
      sections: [
        _DocumentSection(
          title: 'What we collect',
          bullets: [
            'Account details such as email, profile name, role, bio, links, and avatar.',
            'User content such as posts, comments, products, likes, saves, follows, and notifications.',
            'Device-level messaging tokens for push notifications.',
          ],
        ),
        _DocumentSection(
          title: 'Why we use it',
          bullets: [
            'To create your profile and show your public activity in AI Links.',
            'To power feed ranking, product pages, follows, saves, and notifications.',
            'To investigate reports, abuse, and policy violations.',
          ],
        ),
        _DocumentSection(
          title: 'Deletion and retention',
          bullets: [
            'You can initiate account deletion from Settings inside the app.',
            'Deletion removes profile, settings, posts, comments, follows, saves, and related account records.',
            'Operational backups may persist briefly before automatic expiry.',
          ],
        ),
      ],
    );
  }
}

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentPage(
      title: 'Terms of Use',
      sections: [
        _DocumentSection(
          title: 'Use of service',
          bullets: [
            'AI Links is for professional networking around AI, products, and collaboration.',
            'You are responsible for the content, links, and products you publish.',
            'You must not impersonate other people or misrepresent a product or company.',
          ],
        ),
        _DocumentSection(
          title: 'Restricted behavior',
          bullets: [
            'No harassment, spam, scams, hate content, malware links, or illegal content.',
            'No repeated abuse of follows, comments, or product promotion.',
            'No automated scraping or abusive account creation.',
          ],
        ),
        _DocumentSection(
          title: 'Enforcement',
          bullets: [
            'We may remove content, restrict features, or suspend accounts for policy violations.',
            'We may review reports and account activity to keep the network safe.',
          ],
        ),
      ],
    );
  }
}

class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentPage(
      title: 'Community Guidelines',
      sections: [
        _DocumentSection(
          title: 'Expected behavior',
          bullets: [
            'Share real work, real questions, and useful AI resources.',
            'Be clear, respectful, and specific when giving feedback.',
            'Use product pages for actual products and live links you control.',
          ],
        ),
        _DocumentSection(
          title: 'Not allowed',
          bullets: [
            'Harassment, threats, impersonation, coordinated spam, or misleading claims.',
            'Posting unsafe, explicit, or malicious links and files.',
            'Using multiple accounts to manipulate activity counts or feeds.',
          ],
        ),
        _DocumentSection(
          title: 'Safety tools',
          bullets: [
            'You can report posts and users.',
            'You can block a user from your account menu on their profile.',
            'Admins can review the moderation queue and resolve reports.',
          ],
        ),
      ],
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static final Uri _supportEmail = Uri(
    scheme: 'mailto',
    path: 'support@ailinks.app',
    query: 'subject=AI Links Support',
  );

  Future<void> _openEmail() async {
    await launchUrl(_supportEmail, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data == null
            ? 'Loading…'
            : '${snapshot.data!.version} (${snapshot.data!.buildNumber})';

        return Scaffold(
          appBar: AppBar(title: const Text('Support')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _InfoCard(
                title: 'Moderation contact',
                body:
                    'For urgent safety or moderation issues, contact support directly.',
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('support@ailinks.app'),
                  subtitle: const Text('App review, support, moderation'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openEmail,
                ),
              ),
              const SizedBox(height: 12),
              const _InfoCard(
                title: 'Safety workflow',
                body:
                    'Use in-app Report for posts or users first. Use Block from a profile when you do not want further interaction from that account.',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Build information',
                body: 'Current app version: $version',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DocumentPage extends StatelessWidget {
  const _DocumentPage({required this.title, required this.sections});

  final String title;
  final List<_DocumentSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...section.bullets.map(
                    (bullet) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.circle, size: 8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(bullet)),
                        ],
                      ),
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

class _DocumentSection {
  const _DocumentSection({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}
