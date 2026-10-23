class Keyframe {
  const Keyframe({
    required this.id,
    required this.timeSeconds,
    this.speedMultiplier = 1.0,
    this.effectIntensity = 0.0,
    this.opacity = 1.0,
    this.rotationDegrees = 0.0,
  });

  final String id;
  final double timeSeconds;
  final double speedMultiplier; // for speed ramps
  final double effectIntensity; // -1 to 1
  final double opacity; // 0 to 1
  final double rotationDegrees; // 0 to 360

  Keyframe copyWith({
    String? id,
    double? timeSeconds,
    double? speedMultiplier,
    double? effectIntensity,
    double? opacity,
    double? rotationDegrees,
  }) =>
      Keyframe(
        id: id ?? this.id,
        timeSeconds: timeSeconds ?? this.timeSeconds,
        speedMultiplier: speedMultiplier ?? this.speedMultiplier,
        effectIntensity: effectIntensity ?? this.effectIntensity,
        opacity: opacity ?? this.opacity,
        rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      );

  @override
  bool operator ==(Object other) =>
      other is Keyframe &&
      other.id == id &&
      other.timeSeconds == timeSeconds &&
      other.speedMultiplier == speedMultiplier &&
      other.effectIntensity == effectIntensity &&
      other.opacity == opacity &&
      other.rotationDegrees == rotationDegrees;

  @override
  int get hashCode => Object.hash(
    id,
    timeSeconds,
    speedMultiplier,
    effectIntensity,
    opacity,
    rotationDegrees,
  );
}

/// Interpolate between two keyframes at a given time
double interpolateKeyframe(
  Keyframe kf1,
  Keyframe kf2,
  double currentTime,
  double Function(double) value,
) {
  if (currentTime <= kf1.timeSeconds) return value(kf1.timeSeconds);
  if (currentTime >= kf2.timeSeconds) return value(kf2.timeSeconds);

  final t = (currentTime - kf1.timeSeconds) / (kf2.timeSeconds - kf1.timeSeconds);
  final v1 = value(kf1.timeSeconds);
  final v2 = value(kf2.timeSeconds);
  
  // Linear interpolation (ponytail: add easing curves when needed)
  return v1 + (v2 - v1) * t;
}
