import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../projects/domain/media_project.dart';

class AudioTrackManagerSheet extends StatefulWidget {
  const AudioTrackManagerSheet({
    super.key,
    required this.tracks,
    required this.onSave,
  });

  final List<AudioTrack> tracks;
  final Function(List<AudioTrack>) onSave;

  @override
  State<AudioTrackManagerSheet> createState() => _AudioTrackManagerSheetState();
}

class _AudioTrackManagerSheetState extends State<AudioTrackManagerSheet> {
  late List<AudioTrack> _tracks;

  @override
  void initState() {
    super.initState();
    _tracks = List.from(widget.tracks);
  }

  Future<void> _addAudioTrack() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _tracks.add(AudioTrack(source: result.files.single.path!));
      });
    }
  }

  void _removeTrack(int idx) {
    setState(() => _tracks.removeAt(idx));
  }

  void _updateVolume(int idx, double value) {
    setState(() {
      _tracks[idx] = AudioTrack(
        source: _tracks[idx].source,
        volume: value,
        startSeconds: _tracks[idx].startSeconds,
        fadeInSeconds: _tracks[idx].fadeInSeconds,
        fadeOutSeconds: _tracks[idx].fadeOutSeconds,
      );
    });
  }

  void _updateFade(int idx, double fadeIn, double fadeOut) {
    setState(() {
      _tracks[idx] = AudioTrack(
        source: _tracks[idx].source,
        volume: _tracks[idx].volume,
        startSeconds: _tracks[idx].startSeconds,
        fadeInSeconds: fadeIn,
        fadeOutSeconds: fadeOut,
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
                  'Track Audio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _addAudioTrack,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (_tracks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada track audio.',
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
                itemCount: _tracks.length,
                itemBuilder: (ctx, idx) {
                  final track = _tracks[idx];
                  final fileName = track.source.split('/').last;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                fileName,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeTrack(idx),
                              iconSize: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Volume: ${(track.volume * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Slider(
                          value: track.volume,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          label: (track.volume * 100).toStringAsFixed(0),
                          onChanged: (v) => _updateVolume(idx, v),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fade In: ${track.fadeInSeconds.toStringAsFixed(1)}s',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Slider(
                                    value: track.fadeInSeconds,
                                    min: 0,
                                    max: 5,
                                    divisions: 50,
                                    label: track.fadeInSeconds
                                        .toStringAsFixed(1),
                                    onChanged: (v) => _updateFade(
                                      idx,
                                      v,
                                      track.fadeOutSeconds,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fade Out: ${track.fadeOutSeconds.toStringAsFixed(1)}s',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Slider(
                                    value: track.fadeOutSeconds,
                                    min: 0,
                                    max: 5,
                                    divisions: 50,
                                    label: track.fadeOutSeconds
                                        .toStringAsFixed(1),
                                    onChanged: (v) => _updateFade(
                                      idx,
                                      track.fadeInSeconds,
                                      v,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                    widget.onSave(_tracks);
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
