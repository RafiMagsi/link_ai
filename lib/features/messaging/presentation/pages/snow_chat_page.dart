import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/snow_chat_remote_datasource.dart';
import '../providers/snow_chat_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../widgets/snow_chat_bubble.dart';

class SnowChatPage extends ConsumerStatefulWidget {
  const SnowChatPage({super.key});

  @override
  ConsumerState<SnowChatPage> createState() => _SnowChatPageState();
}

class _SnowChatPageState extends ConsumerState<SnowChatPage> {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          'Hey there! I\'m Snow, your AI assistant. How can I help you today?',
      'isUser': false,
      'timestamp': DateTime.now(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;
    _messageController.clear();

    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final history = _messages
          .take(_messages.length - 1)
          .map(
            (message) => SnowChatMessagePayload(
              role: message['isUser'] == true ? 'user' : 'assistant',
              text: message['text'] as String,
            ),
          )
          .toList();

      final reply = await ref
          .read(snowChatRemoteDataSourceProvider)
          .sendMessage(message: userMessage, history: history);

      if (!mounted) return;
      setState(() {
        _messages.add({
          'text': reply,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
      _scrollToBottom();
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Snow request failed.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Snow request failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoldSubscriber = ref.watch(isGoldSubscriberProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Snow AI'), centerTitle: true),
      body: isGoldSubscriber ? _buildChatUI() : _buildLockedUI(),
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return SnowChatBubble(
                text: message['text'],
                isUser: message['isUser'],
                timestamp: message['timestamp'],
              );
            },
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Text('Snow is thinking...'),
              ],
            ),
          ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask Snow anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _isLoading ? null : _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Snow AI is a Gold Feature',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to Gold to chat with Snow AI',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push('/subscription'),
                child: const Text('Get Gold'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
