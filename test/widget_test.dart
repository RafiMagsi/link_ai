// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_ai/app/link_ai_app.dart';
import 'package:link_ai/router/app_router.dart';

void main() {
  testWidgets('LinkAiApp builds (router overridden)', (
    WidgetTester tester,
  ) async {
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('Test Home'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(testRouter)],
        child: const LinkAiApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Test Home'), findsOneWidget);
  });
}
