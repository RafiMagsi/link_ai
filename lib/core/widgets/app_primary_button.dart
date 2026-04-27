import 'package:flutter/material.dart';

import 'app_loader.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: AppLoader(size: 18, strokeWidth: 2),
          )
        : Text(label);

    if (leading != null && !isLoading) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: leading!,
        label: child,
      );
    }

    return FilledButton(onPressed: onPressed, child: child);
  }
}
