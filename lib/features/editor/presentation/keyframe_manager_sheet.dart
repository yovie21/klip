import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/keyframe.dart';

class KeyframeManagerSheet extends StatefulWidget {
  const KeyframeManagerSheet({
    super.key,
    required this.keyframes,
    required this.videoDuration,
    required this.onSave,
  });

  final List<Keyframe> keyframes;
  final double videoDuration;
  final Function(List<Keyframe>) onSave;

  @override
  State<KeyframeManagerSheet> createState() => _KeyframeManagerSheetState();
}

class _KeyframeManagerSheetState extends State<KeyframeManagerSheet> {
  late List<Keyframe> _keyframes;

  @override
  void initState() {
    super.initState();
    _keyframes = List.from(widget.keyframes);
  }

  void _addKeyframe() {
    setState(() {
      _keyframes.add(Keyframe(
        id: const Uuid().v4(),
        timeSeconds: (widget.videoDuration / 2).clamp(0, widget.videoDuration),
        speedMultiplier: 1.0,
        effectIntensity: 0.0,
        opacity: 1.0,
        rotationDegrees: 0.0,
      ));
      _keyframes.sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
    });
  }

  void _removeKeyframe(String id) {
    setState(() => _keyframes.removeWhere((kf) => kf.id == id));
  }

  void _editKeyframe(Keyframe keyframe) {
    showDialog(
      context: context,
      builder: (ctx) => KeyframeEditorDialog(
        keyframe: keyframe,
        videoDuration: widget.videoDuration,
        onSave: (edited) {
          setState(() {
            final idx = _keyframes.indexWhere((kf) => kf.id == keyframe.id);
            if (idx >= 0) {
              _keyframes[idx] = edited;
              _keyframes.sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
            }
          });
          Navigator.pop(ctx);
        },
      ),
    );
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
                  'Keyframes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Tambah keyframe',
                  onPressed: _addKeyframe,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_keyframes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada keyframe.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const Divider(),
                itemCount: _keyframes.length,
                itemBuilder: (ctx, idx) {
                  final kf = _keyframes[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keyframe ${idx + 1}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${kf.timeSeconds.toStringAsFixed(2)}s | Speed: ${kf.speedMultiplier.toStringAsFixed(2)}x | Effect: ${(kf.effectIntensity * 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editKeyframe(kf),
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeKeyframe(kf.id),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
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
                    widget.onSave(_keyframes);
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

class KeyframeEditorDialog extends StatefulWidget {
  const KeyframeEditorDialog({
    super.key,
    required this.keyframe,
    required this.videoDuration,
    required this.onSave,
  });

  final Keyframe keyframe;
  final double videoDuration;
  final Function(Keyframe) onSave;

  @override
  State<KeyframeEditorDialog> createState() => _KeyframeEditorDialogState();
}

class _KeyframeEditorDialogState extends State<KeyframeEditorDialog> {
  late double _time;
  late double _speed;
  late double _effect;
  late double _opacity;
  late double _rotation;

  @override
  void initState() {
    super.initState();
    _time = widget.keyframe.timeSeconds;
    _speed = widget.keyframe.speedMultiplier;
    _effect = widget.keyframe.effectIntensity;
    _opacity = widget.keyframe.opacity;
    _rotation = widget.keyframe.rotationDegrees;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Keyframe'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waktu: ${_time.toStringAsFixed(2)}s',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Slider(
              value: _time,
              min: 0,
              max: widget.videoDuration,
              onChanged: (v) => setState(() => _time = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Kecepatan: ${_speed.toStringAsFixed(2)}x',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Slider(
              value: _speed,
              min: 0.25,
              max: 4.0,
              onChanged: (v) => setState(() => _speed = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Effect: ${(_effect * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Slider(
              value: _effect,
              min: -1,
              max: 1,
              onChanged: (v) => setState(() => _effect = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Opacity: ${(_opacity * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Slider(
              value: _opacity,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => _opacity = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Rotasi: ${_rotation.toStringAsFixed(0)}°',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Slider(
              value: _rotation,
              min: 0,
              max: 360,
              onChanged: (v) => setState(() => _rotation = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(Keyframe(
              id: widget.keyframe.id,
              timeSeconds: _time,
              speedMultiplier: _speed,
              effectIntensity: _effect,
              opacity: _opacity,
              rotationDegrees: _rotation,
            ));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
