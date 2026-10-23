import 'package:flutter/material.dart';
import '../domain/transition_type.dart';

class TransitionPickerBottomSheet extends StatefulWidget {
  const TransitionPickerBottomSheet({
    super.key,
    required this.currentType,
    required this.duration,
    required this.onSave,
  });

  final TransitionType currentType;
  final double duration;
  final Function(TransitionType type, double duration) onSave;

  @override
  State<TransitionPickerBottomSheet> createState() =>
      _TransitionPickerBottomSheetState();
}

class _TransitionPickerBottomSheetState
    extends State<TransitionPickerBottomSheet> {
  late TransitionType _selected;
  late double _duration;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentType;
    _duration = widget.duration;
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
              'Pilih Transisi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TransitionType.values.map((t) {
                final isSelected = t == _selected;
                return ChoiceChip(
                  label: Text(t.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selected = t);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Durasi: ${_duration.toStringAsFixed(2)}s',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _duration,
              min: 0,
              max: 3,
              divisions: 60,
              label: _duration.toStringAsFixed(2),
              onChanged: (value) => setState(() => _duration = value),
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
                    widget.onSave(_selected, _duration);
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
