import 'package:flutter/material.dart';
import '../domain/video_effect.dart';

class EffectPreviewWidget extends StatefulWidget {
  const EffectPreviewWidget({
    super.key,
    required this.effect,
    required this.onIntensityChange,
  });

  final VideoEffect effect;
  final Function(double) onIntensityChange;

  @override
  State<EffectPreviewWidget> createState() => _EffectPreviewWidgetState();
}

class _EffectPreviewWidgetState extends State<EffectPreviewWidget> {
  late double _intensity;

  @override
  void initState() {
    super.initState();
    _intensity = widget.effect.intensity;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.effect.type.displayName,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _intensity,
                min: -1,
                max: 1,
                onChanged: (v) {
                  setState(() => _intensity = v);
                  widget.onIntensityChange(v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(_intensity * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: _getColorFilter(_intensity),
                      child: Container(
                        color: Colors.blue.shade200,
                        child: const Center(
                          child: Text(
                            'Preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ColorFilter _getColorFilter(double intensity) {
    switch (widget.effect.type) {
      case EffectType.brightness:
        return ColorFilter.matrix([
          1 + intensity, 0, 0, 0, 0,
          0, 1 + intensity, 0, 0, 0,
          0, 0, 1 + intensity, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case EffectType.contrast:
        final c = 1 + intensity;
        return ColorFilter.matrix([
          c, 0, 0, 0, -0.5 * c + 0.5,
          0, c, 0, 0, -0.5 * c + 0.5,
          0, 0, c, 0, -0.5 * c + 0.5,
          0, 0, 0, 1, 0,
        ]);
      case EffectType.saturation:
        final s = (intensity + 1) / 2;
        return ColorFilter.matrix([
          0.299 * (1 - s) + s, 0.587 * (1 - s), 0.114 * (1 - s), 0, 0,
          0.299 * (1 - s), 0.587 * (1 - s) + s, 0.114 * (1 - s), 0, 0,
          0.299 * (1 - s), 0.587 * (1 - s), 0.114 * (1 - s) + s, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case EffectType.grayscale:
        return ColorFilter.matrix([
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case EffectType.sepia:
        return ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case EffectType.invert:
        return ColorFilter.matrix([
          -1, 0, 0, 0, 1,
          0, -1, 0, 0, 1,
          0, 0, -1, 0, 1,
          0, 0, 0, 1, 0,
        ]);
      default:
        return ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }
}
