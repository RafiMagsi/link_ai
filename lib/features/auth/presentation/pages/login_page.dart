import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FilledButton(
            onPressed: () => context.go('/feed'),
            child: const Text('Continue to LinkAI'),
          ),
        ),
      ),
    );
  }
}