import 'package:flutter/material.dart';
import '../domain/video_effect.dart';

class EffectEditorBottomSheet extends StatefulWidget {
  const EffectEditorBottomSheet({
    super.key,
    required this.effects,
    required this.onSave,
  });

  final List<VideoEffect> effects;
  final Function(List<VideoEffect>) onSave;

  @override
  State<EffectEditorBottomSheet> createState() =>
      _EffectEditorBottomSheetState();
}

class _EffectEditorBottomSheetState extends State<EffectEditorBottomSheet> {
  late List<VideoEffect> _effects;

  @override
  void initState() {
    super.initState();
    _effects = List.from(widget.effects);
  }

  void _addEffect(EffectType type) {
    setState(() {
      _effects.add(VideoEffect(type: type, intensity: 0));
    });
  }

  void _removeEffect(int idx) {
    setState(() => _effects.removeAt(idx));
  }

  void _updateIntensity(int idx, double value) {
    setState(() {
      _effects[idx] = VideoEffect(
        type: _effects[idx].type,
        intensity: value,
        startSeconds: _effects[idx].startSeconds,
        endSeconds: _effects[idx].endSeconds,
      );
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
                  'Efek Video',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                PopupMenuButton<EffectType>(
                  onSelected: _addEffect,
                  itemBuilder: (ctx) => EffectType.values
                      .map(
                        (t) => PopupMenuItem(
                          value: t,
                          child: Text(t.label),
                        ),
                      )
                      .toList(),
                  child: const Icon(Icons.add),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (_effects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada efek. Tambah dari menu atas.',
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
                itemCount: _effects.length,
                itemBuilder: (ctx, idx) {
                  final effect = _effects[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              effect.type.label,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeEffect(idx),
                              iconSize: 20,
                            ),
                          ],
                        ),
                        Slider(
                          value: effect.intensity,
                          min: -1,
                          max: 1,
                          divisions: 20,
                          label: effect.intensity.toStringAsFixed(2),
                          onChanged: (v) => _updateIntensity(idx, v),
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
                    widget.onSave(_effects);
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
