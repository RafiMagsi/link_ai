import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/snow_chat_remote_datasource.dart';

final snowChatFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final snowChatRemoteDataSourceProvider = Provider<SnowChatRemoteDataSource>((
  ref,
) {
  return SnowChatRemoteDataSource(ref.watch(snowChatFunctionsProvider));
});
