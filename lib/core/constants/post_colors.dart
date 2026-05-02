import 'dart:math';
import 'package:flutter/material.dart';

class PostColors {
  static const List<String> colorCodes = [
    '0xFF60A5FA', // blue
    '0xFFF9A8D4', // pink
    '0xFF34D399', // teal
    '0xFFFCD34D', // yellow
    '0xFFA78BFA', // purple
    '0xFFFB7185', // rose
    '0xFF6EE7B7', // emerald
    '0xFF93C5FD', // light blue
    '0xFFFBBF24', // amber
    '0xFFC084FC', // violet
  ];

  static String getRandomColor() {
    return colorCodes[Random().nextInt(colorCodes.length)];
  }

  static Color colorFromHex(String hexString) {
    try {
      return Color(int.parse(hexString));
    } catch (e) {
      return const Color(0xFF60A5FA); // default to blue
    }
  }
}
