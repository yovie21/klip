import 'package:flutter/material.dart';

class SpeedRampPickerSheet extends StatefulWidget {
  const SpeedRampPickerSheet({
    super.key,
    required this.speedStart,
    required this.speedEnd,
    required this.onSave,
  });

  final double speedStart;
  final double speedEnd;
  final Function(double speedStart, double speedEnd) onSave;

  @override
  State<SpeedRampPickerSheet> createState() => _SpeedRampPickerSheetState();
}

class _SpeedRampPickerSheetState extends State<SpeedRampPickerSheet> {
  late double _speedStart;
  late double _speedEnd;

  @override
  void initState() {
    super.initState();
    _speedStart = widget.speedStart;
    _speedEnd = widget.speedEnd;
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
              'Speed Ramp (Variable Speed)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Kecepatan Awal: ${_speedStart.toStringAsFixed(2)}x',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _speedStart,
              min: 0.25,
              max: 4,
              divisions: 75,
              label: _speedStart.toStringAsFixed(2),
              onChanged: (value) => setState(() => _speedStart = value),
            ),
            const SizedBox(height: 24),
            Text(
              'Kecepatan Akhir: ${_speedEnd.toStringAsFixed(2)}x',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _speedEnd,
              min: 0.25,
              max: 4,
              divisions: 75,
              label: _speedEnd.toStringAsFixed(2),
              onChanged: (value) => setState(() => _speedEnd = value),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Awal', style: TextStyle(fontSize: 12)),
                          Text(
                          '${_speedStart.toStringAsFixed(2)}x',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff25d9e6),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey[600],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Akhir', style: TextStyle(fontSize: 12)),
                          Text(
                          '${_speedEnd.toStringAsFixed(2)}x',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff25d9e6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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
                    widget.onSave(_speedStart, _speedEnd);
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
