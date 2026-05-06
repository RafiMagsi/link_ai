import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ai_assist_remote_datasource.dart';

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final aiAssistRemoteDataSourceProvider = Provider<AiAssistRemoteDataSource>((
  ref,
) {
  return AiAssistRemoteDataSource(ref.watch(firebaseFunctionsProvider));
});
