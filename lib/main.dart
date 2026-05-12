import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'app/link_ai_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture all unhandled exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    final errorMsg = details.exceptionAsString();
    developer.log(
      'FlutterError: $errorMsg',
      stackTrace: details.stack,
      level: 1000,
      name: 'LinkAI.FlutterError',
    );
    debugPrint('════════════ FLUTTER ERROR ════════════');
    debugPrint('Message: $errorMsg');
    if (details.stack != null) {
      debugPrint('Stack Trace:');
      debugPrint(details.stack.toString());
    }
    debugPrint('════════════════════════════════════════');
  };

  // Capture platform dispatcher errors (assertions, etc)
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    developer.log(
      'PlatformError: $error',
      stackTrace: stackTrace,
      level: 1000,
      name: 'LinkAI.PlatformError',
    );
    debugPrint('════════════ PLATFORM ERROR ═══════════');
    debugPrint('Message: $error');
    debugPrint('Stack Trace:');
    debugPrint(stackTrace.toString());
    debugPrint('════════════════════════════════════════');
    return true;
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: LinkAiApp(),
    ),
  );
}