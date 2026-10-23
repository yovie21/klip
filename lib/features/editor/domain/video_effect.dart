enum EffectType {
  brightness('eq=brightness', 'Kecerahan'),
  contrast('eq=contrast', 'Kontras'),
  saturation('eq=saturation', 'Saturasi'),
  hue('hue_rotate', 'Hue Rotation'),
  blur('boxblur', 'Blur'),
  sharpen('unsharp', 'Sharpen'),
  vignette('vignette', 'Vignette'),
  colorize('colorize', 'Colorize'),
  grayscale('format=gray', 'Grayscale'),
  sepia('sepia', 'Sepia'),
  invert('negate', 'Invert'),
  temperature('colortemperature', 'Temperature'),
  vibrance('vibrance', 'Vibrance'),
  exposure('exposure', 'Exposure');

  const EffectType(this.ffmpegFilter, this.label);
  final String ffmpegFilter;
  final String label;
  
  String get displayName => label;
}

class VideoEffect {
  const VideoEffect({
    required this.type,
    required this.intensity, // 0.0 - 1.0 or -1.0 - 1.0 depending on type
    this.startSeconds = 0,
    this.endSeconds = double.infinity,
  });

  final EffectType type;
  final double intensity;
  final double startSeconds;
  final double endSeconds;

  String toFFmpegFilter() {
    switch (type) {
      case EffectType.brightness:
        return 'eq=brightness=${intensity.clamp(-1, 1)}';
      case EffectType.contrast:
        return 'eq=contrast=${(intensity * 2).clamp(0, 5)}';
      case EffectType.saturation:
        return 'eq=saturation=${(intensity + 1).clamp(0, 3)}';
      case EffectType.hue:
        return 'hue_rotate=${intensity * 180}';
      case EffectType.blur:
        return 'boxblur=${(intensity * 10).toStringAsFixed(1)}';
      case EffectType.sharpen:
        return 'unsharp=5:5:${intensity * 2}';
      case EffectType.vignette:
        return 'vignette=sigma=${intensity * 0.3}';
      case EffectType.colorize:
        return 'colorize=h=${intensity * 360}:s=1:l=0.5';
      case EffectType.grayscale:
        return 'format=gray';
      case EffectType.sepia:
        return 'sepia=intensity=${(intensity + 1).clamp(0, 2)}';
      case EffectType.invert:
        return 'negate';
      case EffectType.temperature:
        return 'colortemperature=${3000 + intensity * 5000}';
      case EffectType.vibrance:
        return 'vibrance=${(intensity * 0.5).clamp(-1, 1)}';
      case EffectType.exposure:
        return 'exposure=$intensity';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is VideoEffect &&
      other.type == type &&
      other.intensity == intensity &&
      other.startSeconds == startSeconds &&
      other.endSeconds == endSeconds;

  @override
  int get hashCode =>
      Object.hash(type, intensity, startSeconds, endSeconds);
}
