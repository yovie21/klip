class ColorGrading {
  const ColorGrading({
    this.hueShift = 0,
    this.saturation = 0,
    this.lightness = 0,
    this.shadows = 0,
    this.midtones = 0,
    this.highlights = 0,
  });

  final double hueShift; // -180 to 180
  final double saturation; // -1 to 1
  final double lightness; // -1 to 1
  final double shadows; // -1 to 1 (darken/brighten shadows)
  final double midtones; // -1 to 1
  final double highlights; // -1 to 1 (darken/brighten highlights)

  String toFFmpegFilter() {
    final filters = <String>[];
    
    // Hue shift
    if (hueShift.abs() > 0.01) {
      filters.add('hue=h=$hueShift');
    }
    
    // Saturation
    if (saturation.abs() > 0.01) {
      filters.add('eq=saturation=${1 + saturation}');
    }
    
    // Lightness (brightness + contrast combo for curves)
    if (lightness.abs() > 0.01) {
      filters.add('eq=brightness=${lightness * 0.3}:contrast=${1 + lightness * 0.2}');
    }
    
    // Shadows/Midtones/Highlights (ponytail: FFmpeg curve filter not standard; use levels proxy)
    if (shadows.abs() > 0.01 || midtones.abs() > 0.01 || highlights.abs() > 0.01) {
      // levels=in_black=0:in_white=255:out_black=out:out_white=255
      final outBlack = (shadows * -50).clamp(-255, 0);
      final outWhite = 255 + (highlights * 50).clamp(-50, 255);
      filters.add('levels=in_black=0:in_white=255:out_black=${outBlack.toInt()}:out_white=${outWhite.toInt()}');
    }
    
    return filters.join(',');
  }

  ColorGrading copyWith({
    double? hueShift,
    double? saturation,
    double? lightness,
    double? shadows,
    double? midtones,
    double? highlights,
  }) =>
      ColorGrading(
        hueShift: hueShift ?? this.hueShift,
        saturation: saturation ?? this.saturation,
        lightness: lightness ?? this.lightness,
        shadows: shadows ?? this.shadows,
        midtones: midtones ?? this.midtones,
        highlights: highlights ?? this.highlights,
      );

  @override
  bool operator ==(Object other) =>
      other is ColorGrading &&
      other.hueShift == hueShift &&
      other.saturation == saturation &&
      other.lightness == lightness &&
      other.shadows == shadows &&
      other.midtones == midtones &&
      other.highlights == highlights;

  @override
  int get hashCode => Object.hash(
    hueShift,
    saturation,
    lightness,
    shadows,
    midtones,
    highlights,
  );
}
