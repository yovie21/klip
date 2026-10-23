import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../core/app_theme.dart';
import '../../projects/domain/media_project.dart';
import '../data/media_export_service.dart';
import '../domain/text_style_preset.dart';
import '../domain/video_segment.dart';
import '../domain/video_edit_history.dart';
import '../domain/video_effect.dart';
import '../domain/video_overlay.dart';
import '../domain/color_grading.dart';
import '../domain/keyframe.dart';
import 'transition_picker_sheet.dart';
import 'keyframe_manager_sheet.dart';
import 'effect_editor_sheet.dart';
import 'audio_track_manager_sheet.dart';
import 'overlay_manager_sheet.dart';
import 'speed_ramp_picker_sheet.dart';
import 'color_grading_sheet.dart';
import 'text_animation_sheet.dart';
import 'export_settings_sheet.dart';
import 'realtime_preview_widget.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.project});
  final MediaProject project;
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _exporter = MediaExportService();
  VideoPlayerController? _player;
  final Map<String, VideoPlayerController> _players = {};
  String? _video;
  String? _audio;
  String _text = '';
  String _textStyleId = 'classic';
  double _textSize = 32;
  String _tool = 'Edit';
  bool _busy = false, _muted = false, _advancingSegment = false;
  double _start = 0, _end = 0, _speed = 1, _brightness = 0, _saturation = 1;
  List<VideoSegment> _segments = [];
  List<VideoEffect> _effects = [];
  List<AudioTrack> _audioTracks = [];
  List<VideoOverlay> _overlays = [];
  ColorGrading _colorGrading = const ColorGrading();
  List<Keyframe> _keyframes = [];
  ExportQuality _exportQuality = ExportQuality.hd;
  ExportCodec _exportCodec = ExportCodec.h264;
  TextAnimationType _textEntranceAnimation = TextAnimationType.none;
  TextAnimationType _textExitAnimation = TextAnimationType.none;
  VideoEditHistory? _history;
  int _selectedSegment = 0;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _video = widget.project.clips
        .cast<String?>()
        .firstWhere((p) => p != null && _isVideo(p), orElse: () => null);
    if (_video != null) _initVideo(_video!);
  }

  bool _isVideo(String p) => ['.mp4', '.mov', '.m4v', '.3gp', '.webm']
      .any((e) => p.toLowerCase().endsWith(e));

  Future<void> _initVideo(String path, {bool append = false}) async {
    final next = VideoPlayerController.file(File(path));
    try {
      await next.initialize();
      next.addListener(_onPlaybackTick);
      if (_muted) await next.setVolume(0);
      if (!mounted) {
        await next.dispose();
        return;
      }
      if (append) {
        _players[path] = next;
      } else {
        for (final controller in _players.values) {
          await controller.dispose();
        }
        _players
          ..clear()
          ..[path] = next;
        await _player?.dispose();
      }
      setState(() {
        _player = next;
        _duration = next.value.duration;
        _start = 0;
        _end = _duration.inMilliseconds / 1000;
        final added = VideoSegment(
            startSeconds: _start, endSeconds: _end, sourcePath: path);
        if (append && _history != null) {
          _history!.append(added);
          _segments = _history!.segments;
          _selectedSegment = _segments.length - 1;
        } else {
          _history = VideoEditHistory([added]);
          _segments = [];
          _selectedSegment = 0;
        }
      });
    } catch (_) {
      await next.dispose();
      if (mounted) _message('Video tidak dapat diputar.');
    }
  }

  @override
  void dispose() {
    for (final controller in _players.values) {
      controller.dispose();
    }
    _player?.dispose();
    super.dispose();
  }

  double get _timelineDuration => _segments.isEmpty
      ? _duration.inMilliseconds / 1000
      : _segments.fold<double>(
          0,
          (sum, clip) =>
              sum +
              clip.endSeconds -
              clip.startSeconds -
              clip.transitionAfterSeconds);

  double get _globalPlayhead {
    final segments = _history?.segments ?? _segments;
    if (segments.isEmpty) {
      return _player?.value.position.inMilliseconds.toDouble() ?? 0;
    }
    final before = segments.take(_selectedSegment).fold<double>(
        0, (sum, clip) => sum + clip.endSeconds - clip.startSeconds);
    final clip = segments[_selectedSegment.clamp(0, segments.length - 1)];
    final local =
        (_player?.value.position.inMilliseconds.toDouble() ?? 0) / 1000 -
            clip.startSeconds;
    return before + local.clamp(0, clip.endSeconds - clip.startSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = _timelineDuration.clamp(1.0, 86400.0);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
          child: Column(children: [
        _topBar(),
        Expanded(
            child: Stack(alignment: Alignment.center, children: [
          if (_player?.value.isInitialized == true)
            AspectRatio(
              aspectRatio: _player!.value.aspectRatio,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_previewColorMatrix),
                child: VideoPlayer(_player!),
              ),
            )
          else if (_video == null)
            const Icon(Icons.add_photo_alternate_outlined,
                size: 60, color: AppTheme.muted)
          else
            const CircularProgressIndicator(),
          if (_text.isNotEmpty) _textPreview(),
          Positioned(
              left: 10,
              child: IconButton.filledTonal(
                  onPressed: _addMedia, icon: const Icon(Icons.add)))
        ])),
        _playbackBar(),
        _timeline(maxSeconds),
        if (_selectedSegment < _segments.length)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: RealtimePreviewWidget(
              videoPath: _segments[_selectedSegment].sourcePath ?? _video ?? '',
              segment: _segments[_selectedSegment],
              effects: _segments[_selectedSegment].effects,
            ),
          ),
        _selectedToolPanel(),
        _toolBar(),
      ])),
    );
  }

  List<double> get _previewColorMatrix {
    final s = _saturation;
    final b = _brightness * 255;
    const r = .213, g = .715, blue = .072;
    return [
      r * (1 - s) + s,
      g * (1 - s),
      blue * (1 - s),
      0,
      b,
      r * (1 - s),
      g * (1 - s) + s,
      blue * (1 - s),
      0,
      b,
      r * (1 - s),
      g * (1 - s),
      blue * (1 - s) + s,
      0,
      b,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  Widget _textPreview() {
    final preset = TextStylePreset.byId(_textStyleId);
    return Positioned(
      top: 28,
      left: 24,
      right: 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: preset.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              if (preset.strokeColor != null)
                Text(
                  _text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: preset.fontFamily,
                    fontSize: _textSize,
                    fontWeight: preset.weight,
                    fontStyle:
                        preset.italic ? FontStyle.italic : FontStyle.normal,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = preset.strokeWidth
                      ..color = preset.strokeColor!,
                  ),
                ),
              Text(
                _text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: preset.fontFamily,
                  fontSize: _textSize,
                  fontWeight: preset.weight,
                  fontStyle:
                      preset.italic ? FontStyle.italic : FontStyle.normal,
                  color: preset.color,
                  shadows: preset.shadow
                      ? const [
                          Shadow(
                              color: Colors.black87,
                              blurRadius: 6,
                              offset: Offset(1, 2))
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => SizedBox(
      height: 54,
      child: Row(children: [
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
        const Spacer(),
        const Text('AI UHD', style: TextStyle(color: AppTheme.muted)),
        const Icon(Icons.expand_more, size: 18),
        const SizedBox(width: 8),
        FilledButton.tonal(
            onPressed: _openExportSettings,
            child: const Icon(Icons.settings, size: 18)),
        const SizedBox(width: 8),
        FilledButton(
            onPressed: _busy ? null : _export,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff25d9e6),
                foregroundColor: Colors.black),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Export')),
        const SizedBox(width: 12),
      ]));

  Widget _playbackBar() => SizedBox(
      height: 42,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        IconButton(
            tooltip: 'Fullscreen preview',
            onPressed: _openFullscreen,
            icon: const Icon(Icons.fullscreen, size: 20)),
        IconButton(
            onPressed: _togglePlay,
            icon: Icon(
                _player?.value.isPlaying == true
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 25)),
        const Text('▣ ON',
            style: TextStyle(fontSize: 11, color: AppTheme.muted)),
        IconButton(
            tooltip: 'Undo edit',
            onPressed: _history?.canUndo == true ? _undoEdit : null,
            icon: const Icon(Icons.undo, size: 19)),
        IconButton(
            tooltip: 'Redo edit',
            onPressed: _history?.canRedo == true ? _redoEdit : null,
            icon: const Icon(Icons.redo, size: 19)),
      ]));

  Widget _timeline(double maxSeconds) {
    final current = _globalPlayhead * 1000;
    return Container(
        color: const Color(0xff121318),
        height: 306,
        padding: const EdgeInsets.only(top: 8),
        child: Column(children: [
          Row(children: [
            const SizedBox(width: 14),
            Text('${_time(current / 1000)} / ${_time(maxSeconds)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
            const Spacer(),
            IconButton(
                onPressed: _addMedia,
                icon: const Icon(Icons.add_box_outlined, size: 19))
          ]),
          SizedBox(
              height: 40,
              child: Stack(children: [
                if (_player != null)
                  Slider(
                    value: _globalPlayhead.clamp(0, maxSeconds),
                    min: 0,
                    max: maxSeconds,
                    onChanged: (value) => _seekTimeline(value),
                    activeColor: const Color(0xff25d9e6),
                    inactiveColor: Colors.white10,
                  ),
                const Center(
                    child: IgnorePointer(
                        child: SizedBox(
                            height: 40,
                            child: VerticalDivider(
                                width: 2, color: Colors.white))))
              ])),
          Expanded(
              child: Row(children: [
            SizedBox(
                width: 38,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.music_note,
                          color:
                              _audio == null ? AppTheme.muted : AppTheme.accent,
                          size: 18),
                      const Text('T', style: TextStyle(color: AppTheme.muted))
                    ])),
            Expanded(
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                        width: 520,
                        child: Column(children: [
                          if (_video == null)
                            _track('＋ Add video', null, onTap: _addMedia)
                          else
                            SizedBox(
                              height: 39,
                              child: Row(
                                children: [
                                  for (var i = 0;
                                      i <
                                          (_segments.isEmpty
                                              ? 1
                                              : _segments.length);
                                      i++) ...[
                                    Expanded(
                                      flex: ((_segments.isEmpty
                                                  ? _end - _start
                                                  : _segments[i].endSeconds -
                                                      _segments[i]
                                                          .startSeconds) *
                                              100)
                                          .round()
                                          .clamp(1, 10000),
                                      child: InkWell(
                                        onTap: () => _selectSegment(i),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 3),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: i == _selectedSegment
                                                ? const Color(0xff14535a)
                                                : const Color(0xff30343a),
                                            border: Border.all(
                                                color: i == _selectedSegment
                                                    ? AppTheme.accent
                                                    : AppTheme.accent
                                                        .withOpacity(.35)),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                              '▶ ${_time((_segments.isEmpty ? _end - _start : _segments[i].endSeconds - _segments[i].startSeconds))}',
                                              maxLines: 1,
                                              overflow: TextOverflow.clip,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white70)),
                                        ),
                                      ),
                                    ),
                                    if (i <
                                        (_segments.isEmpty
                                                ? 1
                                                : _segments.length) -
                                            1)
                                      GestureDetector(
                                        onTap: () =>
                                            _transitionPicker(index: i),
                                        child: Container(
                                          width: 25,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: const Color(0xff19292c),
                                              border: Border.all(
                                                  color: AppTheme.accent),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Icon(
                                              _segments[i].transitionAfterSeconds >
                                                      0
                                                  ? Icons.auto_awesome
                                                  : Icons.add,
                                              size: 14,
                                              color: AppTheme.accent),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          _track(
                              _audio == null
                                  ? '＋ Add audio'
                                  : '♫ ${_audio!.split(Platform.pathSeparator).last}  ×',
                              _audio == null ? null : Icons.music_note,
                              onTap:
                                  _audio == null ? _pickAudio : _removeAudio),
                          _track(_text.isEmpty ? '＋ Add text' : 'T  $_text',
                              _text.isEmpty ? null : Icons.text_fields,
                              onTap: _editText),
                        ])))),
          ])),
          if (_video != null && _duration > Duration.zero)
            Padding(
                padding: const EdgeInsets.fromLTRB(44, 4, 12, 4),
                child: RangeSlider(
                    values: RangeValues(
                        _start.clamp(0, maxSeconds), _end.clamp(0, maxSeconds)),
                    min: 0,
                    max: maxSeconds,
                    onChanged: (v) {
                      if (v.end - v.start < .25) return;
                      setState(() {
                        _start = v.start;
                        _end = v.end;
                      });
                    },
                    labels: RangeLabels(_time(_start), _time(_end)),
                    activeColor: const Color(0xff25d9e6))),
          Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(children: [
                const Spacer(),
                Text('Trim  ${_time(_start)} – ${_time(_end)}',
                    style:
                        const TextStyle(fontSize: 10, color: AppTheme.muted)),
                const SizedBox(width: 12)
              ])),
        ]));
  }

  Widget _track(String title, IconData? icon, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      child: Container(
          height: 39,
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
              color: icon == null
                  ? const Color(0xff202127)
                  : const Color(0xff30343a),
              borderRadius: BorderRadius.circular(5)),
          child: Row(children: [
            if (icon != null) Icon(icon, size: 14, color: AppTheme.accent),
            const SizedBox(width: 6),
            Flexible(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white70))),
            if (onTap != null) const Spacer(),
            if (onTap != null) const Icon(Icons.add, size: 15)
          ])));

  Widget _selectedToolPanel() => SizedBox(
      height: _tool == 'Text' ? 104 : _tool == 'Edit' ? 80 : 64,
      child: _tool == 'Edit'
          ? Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _mini('Split', Icons.content_cut, _splitAtPlayhead),
                _mini('Delete', Icons.delete_outline, _deleteSelectedSegment),
                if (_segments.length > 1)
                  _mini('Transition', Icons.auto_awesome, _openTransitionPicker),
                _mini(_muted ? 'Unmute' : 'Mute',
                    _muted ? Icons.volume_off : Icons.volume_up, _toggleMute),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _mini('Duplicate', Icons.copy, _duplicateSegment),
                _mini('Reverse', Icons.flip, _reverseSegment),
                _mini('Freeze', Icons.pause_circle, _freezeFrame),
                _mini('Speed ${_speed}x', Icons.speed, _speedPicker),
                _mini('Cover', Icons.image_outlined, _cover)
              ]),
            ])
          : _toolControls());

  Widget _toolControls() => switch (_tool) {
        'Audio' =>
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _mini('Add audio', Icons.music_note, _pickAudio),
            _mini('Audio tracks', Icons.multitrack_audio, _openAudioManager),
            _mini(_muted ? 'Unmute clip' : 'Mute clip', Icons.volume_off,
                _toggleMute),
            _mini('Extract audio', Icons.graphic_eq,
                () => _message('Audio diekstrak saat ekspor video.'))
          ]),
        'Text' => _textControls(),
        'Effects' =>
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _mini('Efek', Icons.auto_fix_high, _openEffectEditor),
            _mini('Speed', Icons.speed, _openSpeedRamp),
            _mini('Brightness', Icons.brightness_6, _brightnessPicker),
            _mini('Saturation', Icons.palette_outlined, _saturationPicker),
          ]),
        'Overlay' =>
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _mini('Tambah overlay', Icons.layers, _openOverlayManager),
            _mini('Add photo', Icons.image, _pickPhoto)
          ]),
        'Captions' =>
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _mini('Add text caption', Icons.subtitles, _editText),
            _mini('Auto captions · AI', Icons.auto_awesome,
                () => _message('Auto captions berbasis AI ditunda.'))
          ]),
        'Adjust' =>
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _mini('Grading', Icons.gradient, _openColorGrading),
            _mini('Keyframe', Icons.timeline, _openKeyframeManager),
            _mini('Brightness', Icons.brightness_6, _brightnessPicker),
            _mini('Saturation', Icons.palette_outlined, _saturationPicker),
          ]),
        _ => const SizedBox.shrink(),
      };

  Widget _textControls() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: _mini('Add text', Icons.add, _editText)),
              Expanded(child: _mini('Edit text', Icons.text_fields, _editText)),
              Expanded(
                child: _mini('Remove', Icons.delete_outline, () {
                  setState(() => _text = '');
                }),
              ),
              Expanded(
                  child: _mini('Text style', Icons.auto_awesome, _stylePicker)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _mini('Size', Icons.format_size, _textSizePicker)),
              Expanded(
                  child: _mini('Animation', Icons.movie, _openTextAnimations)),
            ]),
          ],
        ),
      );

  Future<void> _stylePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.72,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: false,
            itemCount: TextStylePreset.all.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final preset = TextStylePreset.all[index];
              final selected = preset.id == _textStyleId;
              return InkWell(
                onTap: () {
                  setState(() => _textStyleId = preset.id);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xff202127),
                    border: Border.all(
                      color:
                          selected ? const Color(0xff25d9e6) : Colors.white24,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    preset.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: preset.color,
                      fontFamily: preset.fontFamily,
                      fontSize: 17,
                      fontWeight: preset.weight,
                      fontStyle:
                          preset.italic ? FontStyle.italic : FontStyle.normal,
                      shadows: preset.shadow
                          ? const [Shadow(color: Colors.black87, blurRadius: 5)]
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _textSizePicker() async {
    double size = _textSize;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Text size'),
          content: Slider(
            value: size,
            min: 16,
            max: 64,
            divisions: 24,
            label: size.round().toString(),
            onChanged: (value) => refresh(() => size = value),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() => _textSize = size);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBar() => SizedBox(
      height: 72,
      child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            'Edit',
            'Audio',
            'Text',
            'Effects',
            'Overlay',
            'Captions',
            'Filters',
            'Adjust',
            'Stickers',
            'Aspect ratio'
          ]
              .map((v) => InkWell(
                  onTap: () => setState(() => _tool = v),
                  child: SizedBox(
                      width: 68,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_toolIcon(v),
                                size: 21,
                                color: _tool == v
                                    ? const Color(0xff25d9e6)
                                    : Colors.white70),
                            const SizedBox(height: 4),
                            Text(v,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _tool == v
                                        ? const Color(0xff25d9e6)
                                        : Colors.white70),
                                maxLines: 1)
                          ]))))
              .toList()));
  IconData _toolIcon(String t) => switch (t) {
        'Audio' => Icons.music_note,
        'Text' => Icons.text_fields,
        'Effects' || 'Filters' => Icons.auto_fix_high,
        'Overlay' => Icons.layers,
        'Captions' => Icons.subtitles,
        'Adjust' => Icons.tune,
        'Stickers' => Icons.emoji_emotions,
        'Aspect ratio' => Icons.aspect_ratio,
        _ => Icons.edit
      };
  Widget _mini(String title, IconData icon, VoidCallback action) => InkWell(
      onTap: action,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 9), maxLines: 1)
      ]));

  Future<void> _seekTimeline(double time) async {
    final segments = _history?.segments ?? _segments;
    if (segments.isEmpty) return;
    var remaining = time;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final length = segment.endSeconds - segment.startSeconds;
      if (remaining <= length || i == segments.length - 1) {
        await _selectSegment(i);
        final target =
            (segment.startSeconds + remaining.clamp(0, length)) * 1000;
        await _player?.seekTo(Duration(milliseconds: target.round()));
        return;
      }
      remaining -= length;
    }
  }

  Future<void> _selectSegment(int index) async {
    final segments = _history?.segments ?? _segments;
    if (index < 0 || index >= segments.length) return;
    final segment = segments[index];
    final path = segment.sourcePath ?? _video;
    if (path == null) return;
    var player = _players[path];
    if (player == null) {
      player = VideoPlayerController.file(File(path));
      try {
        await player.initialize();
        player.addListener(_onPlaybackTick);
        if (_muted) await player.setVolume(0);
        _players[path] = player;
      } catch (_) {
        await player.dispose();
        if (mounted) _message('Klip tidak dapat diputar.');
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedSegment = index;
      _player = player;
      _video = path;
      _duration = player!.value.duration;
      _start = segment.startSeconds;
      _end = segment.endSeconds;
    });
    await player
        .seekTo(Duration(milliseconds: (segment.startSeconds * 1000).round()));
  }

  void _onPlaybackTick() {
    if (!mounted) return;
    final segments = _history?.segments ?? _segments;
    final player = _player;
    if (player == null || segments.isEmpty || _advancingSegment) return;
    final index = _selectedSegment.clamp(0, segments.length - 1);
    final segment = segments[index];
    if (player.value.isPlaying &&
        player.value.position.inMilliseconds >=
            (segment.endSeconds * 1000).floor()) {
      if (index + 1 < segments.length) {
        _advancingSegment = true;
        _advanceToNextSegment(index)
            .whenComplete(() => _advancingSegment = false);
      } else {
        player.pause();
      }
      return;
    }
    setState(() {});
  }

  Future<void> _advanceToNextSegment(int index) async {
    await _selectSegment(index + 1);
    await _player?.play();
  }

  Future<void> _addMedia() async {
    final files = await ImagePicker().pickMultipleMedia();
    if (files.isEmpty || !mounted) return;
    final videos = files.where((file) => _isVideo(file.path));
    for (final file in videos) {
      if (!mounted) return;
      final append = _history != null;
      setState(() => _video ??= file.path);
      await _initVideo(file.path, append: append);
    }
    if (videos.isEmpty) _message('Pilih file video untuk menambah klip.');
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = result?.files.singleOrNull?.path;
    if (path == null || !mounted) return;
    setState(() => _audio = path);
  }

  void _removeAudio() {
    if (_audio == null) return;
    setState(() => _audio = null);
    _message('Audio tambahan dihapus.');
  }

  Future<void> _toggleMute() async {
    final mute = !_muted;
    setState(() => _muted = mute);
    await _player?.setVolume(mute ? 0 : 1);
  }

  @override
  void didUpdateWidget(covariant EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) {
      _muted = false;
      _audio = null;
      _text = '';
      _video = widget.project.clips
          .cast<String?>()
          .firstWhere((p) => p != null && _isVideo(p), orElse: () => null);
      if (_video != null) _initVideo(_video!);
    }
  }

  Future<void> _pickPhoto() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null && mounted) {
      _message('Photo overlay siap ditambahkan ke track.');
    }
  }

  Future<void> _editText() async {
    final c = TextEditingController(text: _text);
    final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Text overlay'),
                content: TextField(
                    controller: c,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Tulis teks')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, c.text),
                      child: const Text('Apply'))
                ]));
    if (result != null && mounted) setState(() => _text = result);
  }

  Future<void> _speedPicker() async {
    final v = await showModalBottomSheet<double>(
        context: context,
        builder: (ctx) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                  padding: EdgeInsets.all(16), child: Text('Playback speed')),
              for (final x in [.5, .75, 1.0, 1.25, 1.5, 2.0])
                ListTile(
                    title: Text('${x}x'), onTap: () => Navigator.pop(ctx, x))
            ])));
    if (v != null && mounted) {
      setState(() => _speed = v);
      await _player?.setPlaybackSpeed(v);
    }
  }

  void _brightnessPicker() =>
      _sliderDialog('Brightness', _brightness, -1, 1, (v) => _brightness = v);
  void _saturationPicker() =>
      _sliderDialog('Saturation', _saturation, 0, 2, (v) => _saturation = v);
  Future<void> _sliderDialog(String title, double initial, double min,
      double max, void Function(double) save) async {
    double value = initial;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, refresh) => AlertDialog(
                    title: Text(title),
                    content: Slider(
                        value: value,
                        min: min,
                        max: max,
                        onChanged: (v) => refresh(() => value = v)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () {
                            save(value);
                            setState(() {});
                            Navigator.pop(ctx);
                          },
                          child: const Text('Apply'))
                    ])));
  }

  Future<void> _filterPicker() async {
    const choices = {'None': 1.0, 'Mono': 0.0, 'Vivid': 1.5, 'Soft': .75};
    final v = await showModalBottomSheet<double>(
        context: context,
        builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: choices.entries
                .map((e) => ListTile(
                    title: Text(e.key),
                    onTap: () => Navigator.pop(ctx, e.value)))
                .toList()));
    if (v != null && mounted) setState(() => _saturation = v);
  }

  Future<void> _trimPanel() async {
    if (_duration == Duration.zero) {
      _message('Pilih video dulu.');
      return;
    }
    final max = _duration.inMilliseconds / 1000;
    double start = _start, end = _end;
    await showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, refresh) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Trim clip'),
                      RangeSlider(
                          values: RangeValues(start, end),
                          min: 0,
                          max: max,
                          onChanged: (v) => refresh(() {
                                start = v.start;
                                end = v.end;
                              })),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Done'))
                    ])))));
    setState(() {
      _start = start;
      _end = end;
    });
  }

  void _splitAtPlayhead() {
    final player = _player;
    if (player == null || !player.value.isInitialized) {
      _message('Pilih video dulu.');
      return;
    }
    final point = player.value.position.inMilliseconds / 1000;
    final current = _history?.segments ??
        [
          VideoSegment(
              startSeconds: _start, endSeconds: _end, sourcePath: _video)
        ];
    final index = _selectedSegment.clamp(0, current.length - 1);
    if (point <= current[index].startSeconds ||
        point >= current[index].endSeconds) {
      _message('Geser playhead ke dalam klip yang dipilih.');
      return;
    }
    if (index < 0) {
      _message('Playhead harus berada di dalam klip.');
      return;
    }
    try {
      final history = _history ?? VideoEditHistory(current);
      history.split(index, point);
      setState(() {
        _history = history;
        _segments = history.segments;
      });
      _message(
          'Split di ${_time(point)} · ${_segments.length} klip di timeline.');
    } on ArgumentError {
      _message('Split harus berjarak minimal 0,25 detik dari tepi klip.');
    }
  }

  Future<void> _transitionPicker({int? index}) async {
    final history = _history;
    final segments = history?.segments ?? _segments;
    final boundary = index ?? _selectedSegment;
    if (history == null || boundary < 0 || boundary >= segments.length - 1) {
      _message('Pilih batas di antara dua klip.');
      return;
    }
    final seconds = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xff202127),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Transisi antar klip',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          for (final option in [
            (0.0, 'Tanpa transisi'),
            (.5, 'Fade · 0,5 dtk'),
            (1.0, 'Fade · 1 dtk')
          ])
            ListTile(
              leading: Icon(option.$1 == 0 ? Icons.block : Icons.auto_awesome,
                  color: AppTheme.accent),
              title:
                  Text(option.$2, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, option.$1),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (seconds == null || !mounted) return;
    try {
      history.setTransition(boundary, seconds);
      setState(() => _segments = history.segments);
      _message(seconds == 0
          ? 'Transisi dihapus.'
          : 'Fade ${seconds.toStringAsFixed(1)} detik diterapkan.');
    } on ArgumentError catch (error) {
      _message('Transisi gagal: $error');
    }
  }

  void _deleteSelectedSegment() {
    final history = _history;
    if (history == null || history.segments.length <= 1) {
      _message('Minimal satu klip harus tersisa.');
      return;
    }
    try {
      history.delete(_selectedSegment.clamp(0, history.segments.length - 1));
      setState(() {
        _segments = history.segments;
        _selectedSegment =
            (_selectedSegment - 1).clamp(0, _segments.length - 1);
      });
    } on RangeError {
      _message('Pilih klip yang ingin dihapus.');
    }
  }

  void _duplicateSegment() {
    if (_selectedSegment >= _segments.length) {
      _message('Pilih segment terlebih dahulu.');
      return;
    }
    final seg = _segments[_selectedSegment];
    final dup = VideoSegment(
      startSeconds: seg.startSeconds,
      endSeconds: seg.endSeconds,
      sourcePath: seg.sourcePath,
      transitionType: seg.transitionType,
      transitionAfterSeconds: seg.transitionAfterSeconds,
      speedStart: seg.speedStart,
      speedEnd: seg.speedEnd,
      effects: List.of(seg.effects),
    );
    setState(() {
      _segments.insert(_selectedSegment + 1, dup);
      _selectedSegment = _selectedSegment + 1;
    });
    _message('Segment diduplikat.');
  }

  void _reverseSegment() {
    if (_selectedSegment >= _segments.length) {
      _message('Pilih segment terlebih dahulu.');
      return;
    }
    final seg = _segments[_selectedSegment];
    setState(() {
      _segments[_selectedSegment] = VideoSegment(
        startSeconds: seg.startSeconds,
        endSeconds: seg.endSeconds,
        sourcePath: seg.sourcePath,
        transitionType: seg.transitionType,
        transitionAfterSeconds: seg.transitionAfterSeconds,
        speedStart: seg.speedEnd,
        speedEnd: seg.speedStart,
        effects: List.of(seg.effects),
      );
    });
    _message('Segment dibalik.');
  }

  void _freezeFrame() {
    if (_selectedSegment >= _segments.length) {
      _message('Pilih segment terlebih dahulu.');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Freeze Frame'),
        content: const Text('Freeze di awal atau akhir?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final seg = _segments[_selectedSegment];
              setState(() {
                _segments[_selectedSegment] = VideoSegment(
                  startSeconds: seg.startSeconds,
                  endSeconds: seg.endSeconds,
                  sourcePath: seg.sourcePath,
                  transitionType: seg.transitionType,
                  transitionAfterSeconds: seg.transitionAfterSeconds,
                  speedStart: 0,
                  speedEnd: seg.speedStart,
                  effects: List.of(seg.effects),
                );
              });
              _message('Freeze di awal.');
            },
            child: const Text('Awal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final seg = _segments[_selectedSegment];
              setState(() {
                _segments[_selectedSegment] = VideoSegment(
                  startSeconds: seg.startSeconds,
                  endSeconds: seg.endSeconds,
                  sourcePath: seg.sourcePath,
                  transitionType: seg.transitionType,
                  transitionAfterSeconds: seg.transitionAfterSeconds,
                  speedStart: seg.speedEnd,
                  speedEnd: 0,
                  effects: List.of(seg.effects),
                );
              });
              _message('Freeze di akhir.');
            },
            child: const Text('Akhir'),
          ),
        ],
      ),
    );
  }

  void _undoEdit() {
    final history = _history;
    if (history == null || !history.undo()) return;
    setState(() {
      _segments = history.segments;
      _selectedSegment = _selectedSegment.clamp(0, _segments.length - 1);
    });
  }

  void _redoEdit() {
    final history = _history;
    if (history == null || !history.redo()) return;
    setState(() => _segments = history.segments);
  }

  Future<void> _cover() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null && mounted) _message('Cover image selected.');
  }

  Future<void> _export() async {
    if (_video == null) {
      _message('Pilih video terlebih dahulu.');
      return;
    }
    setState(() => _busy = true);
    try {
      final path = await _exporter.export(
          input: _video!,
          startSeconds: _start,
          endSeconds: _end,
          speed: _speed,
          mute: _muted,
          audioPath: _audio,
          text: _text,
          textStyleId: _textStyleId,
          textSize: _textSize,
          segments: _segments,
          effects: _effects,
          audioTracks: _audioTracks,
          overlays: _overlays,
          colorGrading: _colorGrading,
          keyframes: _keyframes,
          brightness: _brightness,
          saturation: _saturation,
          textEntranceAnimation: _textEntranceAnimation.ffmpegId,
          textExitAnimation: _textExitAnimation.ffmpegId,
          textAnimationDuration: 0.5,
          exportQuality: _exportQuality,
          exportCodec: _exportCodec);
      if (mounted) _message('Export selesai: $path');
    } catch (e) {
      if (mounted) _message('Export gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openTransitionPicker() {
    if (_selectedSegment >= _segments.length) {
      _message('Pilih segment terlebih dahulu.');
      return;
    }
    final seg = _segments[_selectedSegment];
    showModalBottomSheet(
      context: context,
      builder: (_) => TransitionPickerBottomSheet(
        currentType: seg.transitionType,
        duration: seg.transitionAfterSeconds,
        onSave: (type, duration) {
          setState(() {
            _segments[_selectedSegment] = VideoSegment(
              startSeconds: seg.startSeconds,
              endSeconds: seg.endSeconds,
              sourcePath: seg.sourcePath,
              transitionType: type,
              transitionAfterSeconds: duration,
            );
          });
        },
      ),
    );
  }

  void _openEffectEditor() {
    if (_selectedSegment >= _segments.length) {
      _message('Pilih segment terlebih dahulu.');
      return;
    }
    final seg = _segments[_selectedSegment];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EffectEditorBottomSheet(
        effects: seg.effects,
        onSave: (effects) {
          setState(() {
            _segments[_selectedSegment] = VideoSegment(
              startSeconds: seg.startSeconds,
              endSeconds: seg.endSeconds,
              sourcePath: seg.sourcePath,
              transitionType: seg.transitionType,
              transitionAfterSeconds: seg.transitionAfterSeconds,
              speedStart: seg.speedStart,
              speedEnd: seg.speedEnd,
              effects: effects,
            );
          });
        },
      ),
    );
  }

  void _openAudioManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AudioTrackManagerSheet(
        tracks: _audioTracks,
        onSave: (tracks) {
          setState(() => _audioTracks = tracks);
        },
      ),
    );
  }

  void _openOverlayManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => OverlayManagerSheet(
        overlays: _overlays,
        videoDuration: _end - _start,
        onSave: (overlays) {
          setState(() => _overlays = overlays);
        },
      ),
    );
  }

  void _openSpeedRamp() {
    if (_selectedSegment >= _segments.length) {
      _message('Pilih segment terlebih dahulu.');
      return;
    }
    final seg = _segments[_selectedSegment];
    showModalBottomSheet(
      context: context,
      builder: (_) => SpeedRampPickerSheet(
        speedStart: seg.speedStart,
        speedEnd: seg.speedEnd,
        onSave: (speedStart, speedEnd) {
          setState(() {
            _segments[_selectedSegment] = VideoSegment(
              startSeconds: seg.startSeconds,
              endSeconds: seg.endSeconds,
              sourcePath: seg.sourcePath,
              transitionType: seg.transitionType,
              transitionAfterSeconds: seg.transitionAfterSeconds,
              speedStart: speedStart,
              speedEnd: speedEnd,
            );
          });
        },
      ),
    );
  }

  void _openColorGrading() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ColorGradingSheet(
        colorGrading: _colorGrading,
        onSave: (grading) {
          setState(() => _colorGrading = grading);
        },
      ),
    );
  }

  void _openKeyframeManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => KeyframeManagerSheet(
        keyframes: _keyframes,
        videoDuration: _end - _start,
        onSave: (keyframes) {
          setState(() => _keyframes = keyframes);
        },
      ),
    );
  }

  void _openExportSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExportSettingsSheet(
        quality: _exportQuality,
        codec: _exportCodec,
        onSave: (quality, codec) {
          setState(() {
            _exportQuality = quality;
            _exportCodec = codec;
          });
        },
      ),
    );
  }

  void _openTextAnimations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TextAnimationSheet(
        entranceType: _textEntranceAnimation,
        exitType: _textExitAnimation,
        durationSeconds: 0.5,
        onSave: (entrance, exit, duration) {
          setState(() {
            _textEntranceAnimation = entrance;
            _textExitAnimation = exit;
          });
        },
      ),
    );
  }

  Future<void> _openFullscreen() async {
    final player = _player;
    if (player?.value.isInitialized != true) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _FullscreenVideoPage(
        player: player!,
        colorMatrix: _previewColorMatrix,
      ),
    ));
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    final p = _player;
    if (p == null) return;
    setState(() => p.value.isPlaying ? p.pause() : p.play());
  }

  String _time(double s) {
    final n = s.floor();
    return '${(n ~/ 60).toString().padLeft(2, '0')}:${(n % 60).toString().padLeft(2, '0')}';
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _FullscreenVideoPage extends StatelessWidget {
  const _FullscreenVideoPage({required this.player, required this.colorMatrix});
  final VideoPlayerController player;
  final List<double> colorMatrix;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => player.value.isPlaying ? player.pause() : player.play(),
          child: Stack(fit: StackFit.expand, children: [
            Center(
              child: AspectRatio(
                aspectRatio: player.value.aspectRatio,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(colorMatrix),
                  child: VideoPlayer(player),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Close fullscreen',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.fullscreen_exit),
              ),
            ),
          ]),
        ),
      );
}
