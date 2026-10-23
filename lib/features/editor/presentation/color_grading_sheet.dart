import 'package:flutter/material.dart';
import '../domain/color_grading.dart';

class ColorGradingSheet extends StatefulWidget {
  const ColorGradingSheet({
    super.key,
    required this.colorGrading,
    required this.onSave,
  });

  final ColorGrading colorGrading;
  final Function(ColorGrading) onSave;

  @override
  State<ColorGradingSheet> createState() => _ColorGradingSheetState();
}

class _ColorGradingSheetState extends State<ColorGradingSheet> {
  late double _hueShift;
  late double _saturation;
  late double _lightness;
  late double _shadows;
  late double _midtones;
  late double _highlights;

  @override
  void initState() {
    super.initState();
    _hueShift = widget.colorGrading.hueShift;
    _saturation = widget.colorGrading.saturation;
    _lightness = widget.colorGrading.lightness;
    _shadows = widget.colorGrading.shadows;
    _midtones = widget.colorGrading.midtones;
    _highlights = widget.colorGrading.highlights;
  }

  void _reset() {
    setState(() {
      _hueShift = 0;
      _saturation = 0;
      _lightness = 0;
      _shadows = 0;
      _midtones = 0;
      _highlights = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Color Grading',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _slider('Hue Shift', _hueShift, -180, 180, (v) {
              setState(() => _hueShift = v);
            }),
            _slider('Saturation', _saturation, -1, 1, (v) {
              setState(() => _saturation = v);
            }),
            _slider('Lightness', _lightness, -1, 1, (v) {
              setState(() => _lightness = v);
            }),
            const SizedBox(height: 16),
            Text(
              'Curves',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _slider('Shadows', _shadows, -1, 1, (v) {
              setState(() => _shadows = v);
            }),
            _slider('Midtones', _midtones, -1, 1, (v) {
              setState(() => _midtones = v);
            }),
            _slider('Highlights', _highlights, -1, 1, (v) {
              setState(() => _highlights = v);
            }),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    widget.onSave(ColorGrading(
                      hueShift: _hueShift,
                      saturation: _saturation,
                      lightness: _lightness,
                      shadows: _shadows,
                      midtones: _midtones,
                      highlights: _highlights,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(
                value.toStringAsFixed(2),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
