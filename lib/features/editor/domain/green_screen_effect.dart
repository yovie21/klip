import 'package:flutter/material.dart';

class GreenScreenEffect {
  final Color chromaKey;
  final double similarity;
  final double softness;
  final bool enabled;

  const GreenScreenEffect({
    this.chromaKey = const Color(0xff00ff00),
    this.similarity = 0.3,
    this.softness = 0.1,
    this.enabled = false,
  });

  GreenScreenEffect copyWith({
    Color? chromaKey,
    double? similarity,
    double? softness,
    bool? enabled,
  }) =>
      GreenScreenEffect(
        chromaKey: chromaKey ?? this.chromaKey,
        similarity: similarity ?? this.similarity,
        softness: softness ?? this.softness,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
    'chromaKey': chromaKey.value,
    'similarity': similarity,
    'softness': softness,
    'enabled': enabled,
  };

  factory GreenScreenEffect.fromJson(Map<String, dynamic> json) =>
      GreenScreenEffect(
        chromaKey: Color(json['chromaKey'] as int? ?? 0xff00ff00),
        similarity: json['similarity'] as double? ?? 0.3,
        softness: json['softness'] as double? ?? 0.1,
        enabled: json['enabled'] as bool? ?? false,
      );
}
