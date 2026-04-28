import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

final messagingRemoteDataSourceProvider =
    Provider<MessagingRemoteDataSource>((ref) {
  return MessagingRemoteDataSource(
    ref.watch(firebaseFirestoreProvider),
  );
});

final myInboxProvider = StreamProvider<List<ConversationModel>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref
      .watch(messagingRemoteDataSourceProvider)
      .watchInbox(user.uid);
});

final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref
      .watch(messagingRemoteDataSourceProvider)
      .watchUnreadCount(user.uid);
});

final conversationMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
  return ref
      .watch(messagingRemoteDataSourceProvider)
      .watchMessages(conversationId);
});

final messagingControllerProvider =
    StateNotifierProvider<MessagingController, AsyncValue<void>>((ref) {
  return MessagingController(ref, ref.watch(messagingRemoteDataSourceProvider));
});

class MessagingController extends StateNotifier<AsyncValue<void>> {
  MessagingController(this._ref, this._messagingRemoteDataSource)
    : super(const AsyncData(null));

  final Ref _ref;
  final MessagingRemoteDataSource _messagingRemoteDataSource;

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String otherUid,
    required String otherName,
    required String? otherAvatarUrl,
    required String myName,
    required String? myAvatarUrl,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _messagingRemoteDataSource.sendMessage(
        conversationId: conversationId,
        senderUid: user.uid,
        text: text,
        otherUid: otherUid,
        otherName: otherName,
        otherAvatarUrl: otherAvatarUrl,
        myName: myName,
        myAvatarUrl: myAvatarUrl,
      );

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> markRead({
    required String conversationId,
    required String uid,
  }) async {
    try {
      await _messagingRemoteDataSource.markRead(
        conversationId: conversationId,
        uid: uid,
      );
    } catch (error, stackTrace) {
      debugPrint('Error marking message as read: $error\n$stackTrace');
    }
  }
}
