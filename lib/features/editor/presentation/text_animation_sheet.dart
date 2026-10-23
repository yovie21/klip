import 'package:flutter/material.dart';

enum TextAnimationType {
  none('Tidak ada', 'none'),
  fadeIn('Fade in', 'fade'),
  slideLeft('Geser kiri', 'slideLeft'),
  slideRight('Geser kanan', 'slideRight'),
  slideUp('Geser atas', 'slideUp'),
  slideDown('Geser bawah', 'slideDown'),
  zoomIn('Zoom in', 'zoomIn'),
  popIn('Pop in', 'popIn'),
  bounceIn('Bounce in', 'bounceIn');

  const TextAnimationType(this.label, this.ffmpegId);
  final String label;
  final String ffmpegId; // for FFmpeg drawtext entrance animation
}

class TextAnimationSheet extends StatefulWidget {
  const TextAnimationSheet({
    super.key,
    required this.entranceType,
    required this.exitType,
    required this.durationSeconds,
    required this.onSave,
  });

  final TextAnimationType entranceType;
  final TextAnimationType exitType;
  final double durationSeconds;
  final Function(TextAnimationType entrance, TextAnimationType exit, double duration) onSave;

  @override
  State<TextAnimationSheet> createState() => _TextAnimationSheetState();
}

class _TextAnimationSheetState extends State<TextAnimationSheet> {
  late TextAnimationType _entranceType;
  late TextAnimationType _exitType;
  late double _duration;

  @override
  void initState() {
    super.initState();
    _entranceType = widget.entranceType;
    _exitType = widget.exitType;
    _duration = widget.durationSeconds;
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
            Text(
              'Animasi Text',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Masuk',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TextAnimationType.values.map((t) {
                final isSelected = t == _entranceType;
                return ChoiceChip(
                  label: Text(t.label, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _entranceType = t);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Keluar',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TextAnimationType.values.map((t) {
                final isSelected = t == _exitType;
                return ChoiceChip(
                  label: Text(t.label, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _exitType = t);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Durasi: ${_duration.toStringAsFixed(1)}s',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _duration,
              min: 0.1,
              max: 3,
              divisions: 30,
              label: _duration.toStringAsFixed(1),
              onChanged: (value) => setState(() => _duration = value),
            ),
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
                    widget.onSave(_entranceType, _exitType, _duration);
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
}
