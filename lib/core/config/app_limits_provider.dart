import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_limits.dart';

/// App-wide limits.
///
/// For now this returns local defaults. Later, replace with a Firestore-backed
/// provider that reads `appConfig/global` and falls back to defaults.
final appLimitsProvider = Provider<AppLimits>((ref) => AppLimits.defaults());
