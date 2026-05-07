import 'package:flutter/material.dart';

class GoldBadgeWidget extends StatelessWidget {
  const GoldBadgeWidget({
    super.key,
    this.size = 16,
    this.padding = const EdgeInsets.only(left: 4),
  });

  final double size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Icon(
        Icons.star,
        size: size,
        color: const Color(0xFFFDB022),
      ),
    );
  }
}
