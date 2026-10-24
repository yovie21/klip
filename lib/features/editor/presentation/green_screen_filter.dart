import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../domain/green_screen_effect.dart';

class GreenScreenFilter {
  static ColorFilter createColorFilter(GreenScreenEffect effect) {
    if (!effect.enabled) return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    
    // Chroma key matrix: removes green channel (or selected color)
    // Formula: if color ~= chromaKey within similarity threshold, make transparent
    // ponytail: use FFmpeg's scale filter for production-grade chroma keying
    
    final r = (effect.chromaKey.red / 255.0);
    final g = (effect.chromaKey.green / 255.0);
    final b = (effect.chromaKey.blue / 255.0);
    
    // Simple chroma key: desaturate based on proximity to target color
    // This is a placeholder; real implementation needs OpenGL shader
    return ColorFilter.matrix([
      0.3 + (0.7 * (1 - effect.similarity)), 0.59, 0.11, 0, 0,
      0.3, 0.59 + (0.7 * (1 - effect.similarity)), 0.11, 0, 0,
      0.3, 0.59, 0.11 + (0.7 * (1 - effect.similarity)), 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
}
