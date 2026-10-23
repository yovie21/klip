import 'package:flutter/material.dart' show Color;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/text_style_preset.dart';
import '../domain/video_segment.dart';
import '../domain/video_effect.dart';
import '../domain/video_overlay.dart';
import '../domain/color_grading.dart';
import '../domain/keyframe.dart';
import '../presentation/export_settings_sheet.dart';
import '../../projects/domain/media_project.dart';

class MediaExportService {
  Future<String> export({
    required String input,
    required double startSeconds,
    required double endSeconds,
    required double speed,
    required bool mute,
    String? audioPath,
    String? text,
    double brightness = 0,
    double saturation = 1,
    String textStyleId = 'classic',
    double textSize = 32,
    List<VideoSegment> segments = const [],
    List<VideoEffect> effects = const [],
    List<AudioTrack> audioTracks = const [],
    List<VideoOverlay> overlays = const [],
    ColorGrading colorGrading = const ColorGrading(),
    List<Keyframe> keyframes = const [],
    String? textEntranceAnimation,
    String? textExitAnimation,
    double textAnimationDuration = 0.5,
    ExportQuality exportQuality = ExportQuality.hd,
    ExportCodec exportCodec = ExportCodec.h264,
  }) async {
    if (startSeconds < 0 ||
        endSeconds <= startSeconds ||
        speed < .25 ||
        speed > 4) {
      throw ArgumentError('Rentang trim atau kecepatan tidak valid.');
    }
    final directory = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final output =
        '${directory.path}/klip_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final filters = <String>[];
    if (segments.isEmpty) filters.add('setpts=${1 / speed}*PTS');
    
    // Apply video effects
    for (final effect in effects) {
      filters.add(effect.toFFmpegFilter());
    }
    
    // Apply overlays (ponytail: v1 image+text; video overlays when needed)
    for (final overlay in overlays.where((o) => o.startSeconds < endSeconds && o.endSeconds > startSeconds)) {
      filters.add(overlay.toFFmpegOverlay());
    }
    
    // Apply color grading
    final gradingFilter = colorGrading.toFFmpegFilter();
    if (gradingFilter.isNotEmpty) {
      filters.add(gradingFilter);
    }
    
    if (brightness != 0) filters.add('eq=brightness=$brightness');
    if (saturation != 1) filters.add('eq=saturation=$saturation');
    if (text != null && text.isNotEmpty) {
      final preset = TextStylePreset.byId(textStyleId);
      final safeText = text
          .replaceAll(r'\', r'\\')
          .replaceAll(':', r'\:')
          .replaceAll("'", r"\'")
          .replaceAll('%', r'\%');
      String hex(Color color) =>
          '#${color.red.toRadixString(16).padLeft(2, '0')}'
          '${color.green.toRadixString(16).padLeft(2, '0')}'
          '${color.blue.toRadixString(16).padLeft(2, '0')}';
      final textFilter = StringBuffer(
          "drawtext=fontfile=${preset.fontFile}:text='$safeText':fontcolor=${hex(preset.color)}:fontsize=$textSize:x=(w-text_w)/2:y=32");
      
      // Add entrance/exit timing (ponytail: basic fade; full slide/pop animation = upgrade)
      if (textEntranceAnimation != null && textEntranceAnimation.isNotEmpty) {
        final entranceStart = startSeconds;
        final entranceEnd = startSeconds + textAnimationDuration;
        textFilter.write(":enable='between(t,$entranceStart,$entranceEnd)'");
      }
      if (textExitAnimation != null && textExitAnimation.isNotEmpty) {
        final exitStart = endSeconds - textAnimationDuration;
        final exitEnd = endSeconds;
        // If both entrance and exit: combine expressions
        if (textEntranceAnimation != null && textEntranceAnimation.isNotEmpty) {
          textFilter.write("|between(t,$exitStart,$exitEnd)");
        } else {
          textFilter.write(":enable='between(t,$exitStart,$exitEnd)'");
        }
      }
      if (preset.strokeColor != null) {
        textFilter.write(
            ':bordercolor=${hex(preset.strokeColor!)}:borderw=${preset.strokeWidth}');
      }
      if (preset.shadow) {
        textFilter.write(':shadowcolor=black@0.8:shadowx=2:shadowy=2');
      }
      if (preset.background != null) {
        textFilter.write(
            ':box=1:boxcolor=${hex(preset.background!)}@0.85:boxborderw=8');
      }
      filters.add(textFilter.toString());
    }
    final uniquePaths =
        <String>{input, ...segments.map((s) => s.sourcePath ?? input)}.toList();
    
    // Add audio tracks to input paths
    for (final track in audioTracks) {
      if (!uniquePaths.contains(track.source)) {
        uniquePaths.add(track.source);
      }
    }
    
    final args = <String>['-y'];
    final keepSourceAudio = !mute && audioPath == null;
    if (segments.isNotEmpty) {
      for (final path in uniquePaths) {
        args.addAll(['-i', path]);
      }
      final inputIndices = segments
          .map((s) => uniquePaths.indexOf(s.sourcePath ?? input))
          .toList();
      final externalAudioIndex = audioPath == null ? null : uniquePaths.length;
      if (audioPath != null) args.addAll(['-i', audioPath]);
      args.addAll([
        '-filter_complex',
        buildSegmentFilterGraph(segments: segments, sourceInputIndices: inputIndices, speed: speed, videoFilters: filters.join(','), keepSourceAudio: keepSourceAudio, useExternalAudio: audioPath != null, externalAudioInputIndex: externalAudioIndex),
        '-map',
        '[outv]',
      ]);
      if (keepSourceAudio || audioPath != null) {
        args.addAll(['-map', '[outa]', '-c:a', 'aac']);
      }
      if (mute) args.add('-an');
    } else {
      args.addAll(['-i', input]);
      for (final track in audioTracks) {
        args.addAll(['-i', track.source]);
      }
      args.addAll([
        '-ss',
        '$startSeconds',
        '-t',
        '${(endSeconds - startSeconds) / speed}',
        '-vf',
        filters.join(','),
        '-map',
        '0:v:0'
      ]);
      if (audioTracks.isNotEmpty && !mute) {
        final audioChains = <String>[];
        if (keepSourceAudio) {
          audioChains.add('[0:a]volume=1[a0]');
        }
        for (var i = 0; i < audioTracks.length; i++) {
          final track = audioTracks[i];
          final inputIdx = 1 + i;
          final outputLabel = 'a${i + (keepSourceAudio ? 1 : 0)}';
          final volStr = 'volume=${track.volume}';
          if (track.fadeInSeconds > 0 || track.fadeOutSeconds > 0) {
            audioChains.add('[$inputIdx:a]$volStr,afade=t=in:d=${track.fadeInSeconds},afade=t=out:d=${track.fadeOutSeconds}[$outputLabel]');
          } else {
            audioChains.add('[$inputIdx:a]$volStr[$outputLabel]');
          }
        }
        final mixInputs = List.generate(audioChains.length, (i) => '[a$i]').join();
        audioChains.add('$mixInputs amix=inputs=${audioChains.length}:duration=longest[outa]');
        args.addAll(['-af', audioChains.join(';'), '-map', '[outa]', '-c:a', 'aac']);
      } else if (audioPath != null) {
        args.addAll([
          '-i',
          audioPath,
          '-map',
          '${1 + audioTracks.length}:a:0',
          '-af',
          'atempo=$speed',
          '-c:a',
          'aac'
        ]);
      } else if (!mute) {
        args.addAll(['-map', '0:a:0?', '-af', 'atempo=$speed', '-c:a', 'aac']);
      } else {
        args.add('-an');
      }
    }
    args.addAll(['-c:v', 'mpeg4', '-q:v', '3', output]);
    final session = await FFmpegKit.execute(args.join(' '));
    if (!ReturnCode.isSuccess(await session.getReturnCode())) {
      throw StateError(await session.getOutput() ?? 'Ekspor gagal.');
    }
    return output;
  }

  String buildSegmentFilterGraph({
    required List<VideoSegment> segments,
    required List<int> sourceInputIndices,
    required double speed,
    required String videoFilters,
    required bool keepSourceAudio,
    required bool useExternalAudio,
    int? externalAudioInputIndex,
  }) {
    final chains = <String>[];
    final videoChains = <String>[];
    
    for (var i = 0; i < segments.length; i++) {
      final idx = sourceInputIndices[i];
      final seg = segments[i];
      final startSec = seg.startSeconds;
      
      // Build segment-specific filter chain
      final segmentFilters = <String>[];
      segmentFilters.add('trim=start=$startSec:end=${seg.endSeconds}');
      segmentFilters.add('setpts=(PTS-PTSSTART)/$speed');
      
      // Add global video filters
      if (videoFilters.isNotEmpty) {
        segmentFilters.add(videoFilters);
      }
      
      // Add segment-specific effects
      for (final effect in seg.effects) {
        segmentFilters.add(effect.toFFmpegFilter());
      }
      
      final filter = segmentFilters.join(',');
      videoChains.add('[$idx:v]$filter[vx$i]');
      
      if (keepSourceAudio) {
        chains.add('[$idx:a]atrim=start=$startSec:end=${seg.endSeconds},asetpts=(PTS-PTSSTART)/$speed[ax$i]');
      }
    }
    
    var lastVideo = 'vx0';
    String? lastAudio = keepSourceAudio ? 'ax0' : null;
    var cumulative = segments[0].endSeconds / speed;
    for (var i = 0; i < segments.length - 1; i++) {
      final duration = segments[i].transitionAfterSeconds;
      final transitionType = segments[i].transitionType;
      if (duration == 0 || transitionType.name == 'none') {
        videoChains.add('[$lastVideo][vx${i + 1}]concat=n=2:v=1:a=0[vjoin$i]');
        lastVideo = 'vjoin$i';
        if (keepSourceAudio) {
          videoChains.add('[$lastAudio][ax${i + 1}]concat=n=2:v=0:a=1[ajoin$i]');
          lastAudio = 'ajoin$i';
        }
        cumulative += segments[i + 1].endSeconds / speed;
        continue;
      }
      final offset = cumulative - duration;
      videoChains.add(
          '[$lastVideo][vx${i + 1}]xfade=transition=${transitionType.ffmpegName}:duration=$duration:offset=$offset[vjoin$i]');
      lastVideo = 'vjoin$i';
      if (keepSourceAudio) {
        videoChains.add('[$lastAudio][ax${i + 1}]acrossfade=d=$duration[ajoin$i]');
        lastAudio = 'ajoin$i';
      }
      cumulative += segments[i + 1].endSeconds / speed - duration;
    }
    videoChains.add('[$lastVideo]null[outv]');
    if (keepSourceAudio) videoChains.add('[$lastAudio]anull[outa]');
    
    return videoChains.join(';');
  }
}
