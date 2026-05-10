import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FullScreenPageRoute extends CustomTransitionPage {
  FullScreenPageRoute({
    required super.child,
    super.name,
    super.arguments,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return Stack(
        children: [
          // Fade background
          FadeTransition(
            opacity: animation,
            child: Container(color: Colors.black),
          ),
          // Scale and slide child
          ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        ],
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
