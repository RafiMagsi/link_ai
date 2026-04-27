import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../providers/connect_providers.dart';

class SendConnectRequestPage extends ConsumerStatefulWidget {
  const SendConnectRequestPage({
    super.key,
    required this.receiverUid,
    required this.receiverName,
  });

  final String receiverUid;
  final String receiverName;

  @override
  ConsumerState<SendConnectRequestPage> createState() =>
      _SendConnectRequestPageState();
}

class _SendConnectRequestPageState
    extends ConsumerState<SendConnectRequestPage> {
  final _messageController = TextEditingController();

  static const _maxLength = 280;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();

    if (message.length > _maxLength) {
      _showMessage('Message is too long.');
      return;
    }

    await ref
        .read(connectControllerProvider.notifier)
        .sendRequest(receiverUid: widget.receiverUid, message: message);

    final state = ref.read(connectControllerProvider);

    if (!mounted) return;

    if (state.hasError) {
      _showMessage(_friendlyError(state.error));
      return;
    }

    Navigator.of(context).pop();
  }

  String _friendlyError(Object? error) {
    final raw = error.toString();

    if (raw.contains('resource-exhausted')) {
      return 'Weekly connect request limit reached.';
    }

    if (raw.contains('already-exists')) {
      return 'Connect request already exists or you are already connected.';
    }

    if (raw.contains('unauthenticated')) {
      return 'Please login again.';
    }

    return 'Unable to send connect request.';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(connectControllerProvider);
    final remaining = _maxLength - _messageController.text.length;
    final isOverLimit = remaining < 0;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Send Connect Request')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.xl),
        children: [
          Text(
            'Connect with ${widget.receiverName}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Write a short reason. Keep it useful, not spammy.',
            style: TextStyle(color: colors.mutedText),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _messageController,
            maxLength: _maxLength,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Message optional',
              hintText: 'Hey, I saw what you are building in AI...',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$remaining',
              style: TextStyle(
                color: isOverLimit
                    ? Theme.of(context).colorScheme.error
                    : colors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: controllerState.isLoading || isOverLimit ? null : _send,
            icon: controllerState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: AppLoader(size: 20, strokeWidth: 2),
                  )
                : const Icon(Icons.person_add),
            label: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}
