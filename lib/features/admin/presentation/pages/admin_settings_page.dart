import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_loader.dart';
import '../../data/models/app_config_model.dart';
import '../providers/admin_providers.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  final _postTextMaxLengthController = TextEditingController();
  final _maxMediaPerPostController = TextEditingController();
  final _maxImageSizeMbController = TextEditingController();
  final _maxVideoSizeMbController = TextEditingController();
  final _maxVideoDurationSecondsController = TextEditingController();
  final _postRateLimitPerHourController = TextEditingController();
  final _connectCooldownMinutesController = TextEditingController();

  bool _initialized = false;

  bool _enableReposts = true;
  bool _enableComments = true;
  bool _enableProducts = true;
  bool _enableViralFeed = true;
  String _postDesignStyle = 'twitter';

  @override
  void dispose() {
    _postTextMaxLengthController.dispose();
    _maxMediaPerPostController.dispose();
    _maxImageSizeMbController.dispose();
    _maxVideoSizeMbController.dispose();
    _maxVideoDurationSecondsController.dispose();
    _postRateLimitPerHourController.dispose();
    _connectCooldownMinutesController.dispose();
    super.dispose();
  }

  void _init(AppConfigModel config) {
    if (_initialized) return;

    _postTextMaxLengthController.text = config.postTextMaxLength.toString();
    _maxMediaPerPostController.text = config.maxMediaPerPost.toString();
    _maxImageSizeMbController.text = config.maxImageSizeMb.toString();
    _maxVideoSizeMbController.text = config.maxVideoSizeMb.toString();
    _maxVideoDurationSecondsController.text = config.maxVideoDurationSeconds
        .toString();
    _postRateLimitPerHourController.text = config.postRateLimitPerHour
        .toString();
    _connectCooldownMinutesController.text = config.connectCooldownMinutes
        .toString();

    _enableReposts = config.enableReposts;
    _enableComments = config.enableComments;
    _enableProducts = config.enableProducts;
    _enableViralFeed = config.enableViralFeed;
    _postDesignStyle = config.postDesignStyle;

    _initialized = true;
  }

  int? _parseInt(String value) {
    return int.tryParse(value.trim());
  }

  Future<void> _save(AppConfigModel currentConfig) async {
    final postTextMaxLength = _parseInt(_postTextMaxLengthController.text);
    final maxMediaPerPost = _parseInt(_maxMediaPerPostController.text);
    final maxImageSizeMb = _parseInt(_maxImageSizeMbController.text);
    final maxVideoSizeMb = _parseInt(_maxVideoSizeMbController.text);
    final maxVideoDurationSeconds = _parseInt(
      _maxVideoDurationSecondsController.text,
    );
    final postRateLimitPerHour = _parseInt(
      _postRateLimitPerHourController.text,
    );
    final connectCooldownMinutes = _parseInt(
      _connectCooldownMinutesController.text,
    );

    if (postTextMaxLength == null ||
        maxMediaPerPost == null ||
        maxImageSizeMb == null ||
        maxVideoSizeMb == null ||
        maxVideoDurationSeconds == null ||
        postRateLimitPerHour == null ||
        connectCooldownMinutes == null) {
      _showMessage('All limit fields must be valid numbers.');
      return;
    }

    if (postTextMaxLength < 1 || postTextMaxLength > 5000) {
      _showMessage('Post text length must be between 1 and 5000.');
      return;
    }

    if (maxMediaPerPost < 0 || maxMediaPerPost > 10) {
      _showMessage('Max media per post must be between 0 and 10.');
      return;
    }

    if (maxImageSizeMb < 1 || maxImageSizeMb > 25) {
      _showMessage('Max image size must be between 1MB and 25MB.');
      return;
    }

    if (maxVideoSizeMb < 1 || maxVideoSizeMb > 500) {
      _showMessage('Max video size must be between 1MB and 500MB.');
      return;
    }

    if (maxVideoDurationSeconds < 1 || maxVideoDurationSeconds > 300) {
      _showMessage('Video duration must be between 1 and 300 seconds.');
      return;
    }

    final updatedConfig = currentConfig.copyWith(
      postTextMaxLength: postTextMaxLength,
      maxMediaPerPost: maxMediaPerPost,
      maxImageSizeMb: maxImageSizeMb,
      maxVideoSizeMb: maxVideoSizeMb,
      maxVideoDurationSeconds: maxVideoDurationSeconds,
      enableReposts: _enableReposts,
      enableComments: _enableComments,
      enableProducts: _enableProducts,
      enableViralFeed: _enableViralFeed,
      postRateLimitPerHour: postRateLimitPerHour,
      connectCooldownMinutes: connectCooldownMinutes,
      postDesignStyle: _postDesignStyle,
    );

    await ref
        .read(adminControllerProvider.notifier)
        .updateConfig(updatedConfig);

    final state = ref.read(adminControllerProvider);

    if (state.hasError) {
      _showMessage('Unable to update global settings.');
      return;
    }

    _showMessage('Global settings updated.');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(appConfigProvider);
    final adminControllerState = ref.watch(adminControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        actions: [
          IconButton(
            onPressed: adminControllerState.isLoading
                ? null
                : () async {
                    await ref
                        .read(adminControllerProvider.notifier)
                        .refreshAdminClaim();

                    if (!mounted) return;
                    _showMessage('Admin token refreshed.');
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: configState.when(
        data: (config) {
          _init(config);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Limits',
                children: [
                  ListTile(
                    leading: const Icon(Icons.gpp_maybe_outlined),
                    title: const Text('Moderation Queue'),
                    subtitle: const Text('Review user and post reports'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/reports'),
                  ),
                  _NumberField(
                    controller: _postTextMaxLengthController,
                    label: 'Post text max length',
                  ),
                  _NumberField(
                    controller: _maxMediaPerPostController,
                    label: 'Max media per post',
                  ),
                  _NumberField(
                    controller: _maxImageSizeMbController,
                    label: 'Max image size MB',
                  ),
                  _NumberField(
                    controller: _maxVideoSizeMbController,
                    label: 'Max video size MB',
                  ),
                  _NumberField(
                    controller: _maxVideoDurationSecondsController,
                    label: 'Max video duration seconds',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Feature Flags',
                children: [
                  SwitchListTile(
                    value: _enableReposts,
                    title: const Text('Enable reposts'),
                    onChanged: (value) {
                      setState(() => _enableReposts = value);
                    },
                  ),
                  SwitchListTile(
                    value: _enableComments,
                    title: const Text('Enable comments'),
                    onChanged: (value) {
                      setState(() => _enableComments = value);
                    },
                  ),
                  SwitchListTile(
                    value: _enableProducts,
                    title: const Text('Enable products'),
                    onChanged: (value) {
                      setState(() => _enableProducts = value);
                    },
                  ),
                  SwitchListTile(
                    value: _enableViralFeed,
                    title: const Text('Enable viral feed'),
                    onChanged: (value) {
                      setState(() => _enableViralFeed = value);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Post Design Style',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const <ButtonSegment<String>>[
                            ButtonSegment<String>(
                              value: 'twitter',
                              label: Text('Twitter'),
                            ),
                            ButtonSegment<String>(
                              value: 'snow',
                              label: Text('Snow'),
                            ),
                            ButtonSegment<String>(
                              value: 'modern',
                              label: Text('Modern'),
                            ),
                          ],
                          selected: <String>{_postDesignStyle},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(
                              () => _postDesignStyle = newSelection.first,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Throttles',
                children: [
                  _NumberField(
                    controller: _postRateLimitPerHourController,
                    label: 'Post rate limit per hour',
                  ),
                  _NumberField(
                    controller: _connectCooldownMinutesController,
                    label: 'Connect cooldown minutes',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: adminControllerState.isLoading
                    ? null
                    : () => _save(config),
                child: adminControllerState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Global Settings'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: adminControllerState.isLoading
                    ? null
                    : () {
                        ref
                            .read(adminControllerProvider.notifier)
                            .createDefaultConfigIfMissing();
                      },
                child: const Text('Create Default Config If Missing'),
              ),
            ],
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Unable to load app config. Make sure you are admin and Firestore rules are deployed.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
