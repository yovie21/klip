import 'package:flutter/material.dart';
import '../domain/green_screen_effect.dart';
import 'green_screen_filter.dart';

class GreenScreenSheet extends StatefulWidget {
  final GreenScreenEffect effect;
  final ValueChanged<GreenScreenEffect> onChanged;

  const GreenScreenSheet({
    super.key,
    required this.effect,
    required this.onChanged,
  });

  @override
  State<GreenScreenSheet> createState() => _GreenScreenSheetState();
}

class _GreenScreenSheetState extends State<GreenScreenSheet> {
  late GreenScreenEffect _effect;

  @override
  void initState() {
    super.initState();
    _effect = widget.effect;
  }

  void _updateEffect(GreenScreenEffect newEffect) {
    setState(() => _effect = newEffect);
    widget.onChanged(newEffect);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Green Screen',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Switch(
              value: _effect.enabled,
              onChanged: (v) => _updateEffect(_effect.copyWith(enabled: v)),
            )
          ]),
          const SizedBox(height: 16),
          if (_effect.enabled) ...[
            _colorPickerRow(),
            const SizedBox(height: 12),
            _sliderRow('Similarity', _effect.similarity, 0, 1, (v) =>
                _updateEffect(_effect.copyWith(similarity: v))),
            const SizedBox(height: 12),
            _sliderRow('Softness', _effect.softness, 0, 0.5, (v) =>
                _updateEffect(_effect.copyWith(softness: v))),
          ]
        ]),
      ),
    );
  }

  Widget _colorPickerRow() => GestureDetector(
      onTap: _showColorPicker,
      child: Row(children: [
        const Text('Key Color', style: TextStyle(fontSize: 12)),
        const Spacer(),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _effect.chromaKey,
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(4),
          ),
        )
      ]));

  Widget _sliderRow(String label, double value, double min, double max,
          ValueChanged<double> onChanged) =>
      Column(children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text('${(value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: Colors.white70))
        ]),
        const SizedBox(height: 6),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: const Color(0xff25d9e6),
        )
      ]);

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1a1d22),
        title: const Text('Select Key Color'),
        content: Wrap(
          spacing: 8,
          children: [
            const Color(0xff00ff00), // Green
            const Color(0xff0000ff), // Blue
            const Color(0xffff00ff), // Magenta
            const Color(0xffffff00), // Yellow
            Colors.white,
            Colors.black,
          ]
              .map((c) => GestureDetector(
                  onTap: () {
                    _updateEffect(_effect.copyWith(chromaKey: c));
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: c,
                      border: Border.all(
                        color: _effect.chromaKey == c
                            ? const Color(0xff25d9e6)
                            : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )))
              .toList(),
        ),
      ),
    );
  }
}
