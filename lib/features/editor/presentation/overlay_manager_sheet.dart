import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../domain/video_overlay.dart';

class OverlayManagerSheet extends StatefulWidget {
  const OverlayManagerSheet({
    super.key,
    required this.overlays,
    required this.videoDuration,
    required this.onSave,
  });

  final List<VideoOverlay> overlays;
  final double videoDuration;
  final Function(List<VideoOverlay>) onSave;

  @override
  State<OverlayManagerSheet> createState() => _OverlayManagerSheetState();
}

class _OverlayManagerSheetState extends State<OverlayManagerSheet> {
  late List<VideoOverlay> _overlays;

  @override
  void initState() {
    super.initState();
    _overlays = List.from(widget.overlays);
  }

  Future<void> _addImageOverlay() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _overlays.add(VideoOverlay(
          id: const Uuid().v4(),
          type: OverlayType.image,
          source: result.files.single.path!,
        ));
      });
    }
  }

  void _addTextOverlay() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Text Overlay'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Masukkan text...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _overlays.add(VideoOverlay(
                    id: const Uuid().v4(),
                    type: OverlayType.text,
                    source: controller.text,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _removeOverlay(String id) {
    setState(() => _overlays.removeWhere((o) => o.id == id));
  }

  void _editOverlay(VideoOverlay overlay) {
    showDialog(
      context: context,
      builder: (ctx) => OverlayEditorDialog(
        overlay: overlay,
        videoDuration: widget.videoDuration,
        onSave: (edited) {
          setState(() {
            final idx = _overlays.indexWhere((o) => o.id == overlay.id);
            if (idx >= 0) {
              _overlays[idx] = edited;
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
                  'Overlay',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image),
                      tooltip: 'Tambah gambar',
                      onPressed: _addImageOverlay,
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields),
                      tooltip: 'Tambah text',
                      onPressed: _addTextOverlay,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            if (_overlays.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada overlay.',
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
                itemCount: _overlays.length,
                itemBuilder: (ctx, idx) {
                  final overlay = _overlays[idx];
                  final typeLabel = overlay.type == OverlayType.image
                      ? 'Gambar'
                      : overlay.type == OverlayType.text
                          ? 'Text'
                          : 'Shape';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$typeLabel: ${overlay.source.split('/').last}',
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${overlay.startSeconds.toStringAsFixed(1)}s - ${overlay.endSeconds == double.infinity ? 'End' : overlay.endSeconds.toStringAsFixed(1)}s',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editOverlay(overlay),
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeOverlay(overlay.id),
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
                    widget.onSave(_overlays);
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

class OverlayEditorDialog extends StatefulWidget {
  const OverlayEditorDialog({
    super.key,
    required this.overlay,
    required this.videoDuration,
    required this.onSave,
  });

  final VideoOverlay overlay;
  final double videoDuration;
  final Function(VideoOverlay) onSave;

  @override
  State<OverlayEditorDialog> createState() => _OverlayEditorDialogState();
}

class _OverlayEditorDialogState extends State<OverlayEditorDialog> {
  late double _startSeconds;
  late double _endSeconds;
  late double _x;
  late double _y;
  late double _width;
  late double _height;
  late double _opacity;

  @override
  void initState() {
    super.initState();
    _startSeconds = widget.overlay.startSeconds;
    _endSeconds = widget.overlay.endSeconds == double.infinity
        ? widget.videoDuration
        : widget.overlay.endSeconds;
    _x = widget.overlay.x;
    _y = widget.overlay.y;
    _width = widget.overlay.width;
    _height = widget.overlay.height;
    _opacity = widget.overlay.opacity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Overlay'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waktu: ${_startSeconds.toStringAsFixed(1)}s - ${_endSeconds.toStringAsFixed(1)}s',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Slider(
              value: _startSeconds,
              min: 0,
              max: widget.videoDuration,
              onChanged: (v) => setState(() => _startSeconds = v),
            ),
            Slider(
              value: _endSeconds,
              min: _startSeconds,
              max: widget.videoDuration,
              onChanged: (v) => setState(() => _endSeconds = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Posisi: (${_x.toStringAsFixed(0)}%, ${_y.toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Slider(
              label: 'X',
              value: _x,
              min: 0,
              max: 100,
              onChanged: (v) => setState(() => _x = v),
            ),
            Slider(
              label: 'Y',
              value: _y,
              min: 0,
              max: 100,
              onChanged: (v) => setState(() => _y = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Ukuran: ${_width.toStringAsFixed(0)}% × ${_height.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Slider(
              label: 'Width',
              value: _width,
              min: 10,
              max: 200,
              onChanged: (v) => setState(() => _width = v),
            ),
            Slider(
              label: 'Height',
              value: _height,
              min: 10,
              max: 200,
              onChanged: (v) => setState(() => _height = v),
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
            widget.onSave(VideoOverlay(
              id: widget.overlay.id,
              type: widget.overlay.type,
              source: widget.overlay.source,
              startSeconds: _startSeconds,
              endSeconds: _endSeconds,
              x: _x,
              y: _y,
              width: _width,
              height: _height,
              opacity: _opacity,
              rotation: widget.overlay.rotation,
              zIndex: widget.overlay.zIndex,
            ));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
