import 'package:flutter/material.dart';

enum ExportQuality {
  sd('720p (HD)', 720),
  hd('1080p (Full HD)', 1080),
  fhd('1440p (2K)', 1440),
  uhd('2160p (4K)', 2160);

  const ExportQuality(this.label, this.height);
  final String label;
  final int height;
}

enum ExportCodec {
  h264('H.264 (Kompatibel)', 'libx264'),
  h265('H.265 (Kecil)', 'libx265'),
  vp9('VP9 (Modern)', 'libvpx-vp9');

  const ExportCodec(this.label, this.ffmpegName);
  final String label;
  final String ffmpegName;
}

class ExportSettingsSheet extends StatefulWidget {
  const ExportSettingsSheet({
    super.key,
    required this.quality,
    required this.codec,
    required this.onSave,
  });

  final ExportQuality quality;
  final ExportCodec codec;
  final Function(ExportQuality quality, ExportCodec codec) onSave;

  @override
  State<ExportSettingsSheet> createState() => _ExportSettingsSheetState();
}

class _ExportSettingsSheetState extends State<ExportSettingsSheet> {
  late ExportQuality _quality;
  late ExportCodec _codec;

  @override
  void initState() {
    super.initState();
    _quality = widget.quality;
    _codec = widget.codec;
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
              'Pengaturan Ekspor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Kualitas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(),
              itemCount: ExportQuality.values.length,
              itemBuilder: (_, idx) {
                final q = ExportQuality.values[idx];
                return RadioListTile(
                  title: Text(q.label),
                  value: q,
                  groupValue: _quality,
                  onChanged: (v) {
                    if (v != null) setState(() => _quality = v);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Codec Video',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(),
              itemCount: ExportCodec.values.length,
              itemBuilder: (_, idx) {
                final c = ExportCodec.values[idx];
                return RadioListTile(
                  title: Text(c.label),
                  subtitle: c == ExportCodec.h265
                      ? const Text('File lebih kecil, encode lebih lambat')
                      : c == ExportCodec.vp9
                          ? const Text('Kompresi terbaik, encode paling lambat')
                          : const Text('Kompatibel, encode cepat'),
                  value: c,
                  groupValue: _codec,
                  onChanged: (v) {
                    if (v != null) setState(() => _codec = v);
                  },
                );
              },
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
                    widget.onSave(_quality, _codec);
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
