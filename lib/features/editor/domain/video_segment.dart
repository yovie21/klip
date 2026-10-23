import 'transition_type.dart';
import 'video_effect.dart';

class VideoSegment {
  const VideoSegment({
    required this.startSeconds,
    required this.endSeconds,
    this.sourcePath,
    this.transitionAfterSeconds = 0,
    this.transitionType = TransitionType.fade,
    this.speedStart = 1.0,
    this.speedEnd = 1.0,
    this.effects = const [],
  });

  final double startSeconds;
  final double endSeconds;
  final String? sourcePath;
  final double transitionAfterSeconds;
  final TransitionType transitionType;
  final double speedStart;
  final double speedEnd;
  final List<VideoEffect> effects;

  // Get average speed for this segment
  double get averageSpeed => (speedStart + speedEnd) / 2;

  @override
  bool operator ==(Object other) =>
      other is VideoSegment &&
      other.startSeconds == startSeconds &&
      other.endSeconds == endSeconds &&
      other.sourcePath == sourcePath &&
      other.transitionAfterSeconds == transitionAfterSeconds &&
      other.transitionType == transitionType &&
      other.speedStart == speedStart &&
      other.speedEnd == speedEnd &&
      other.effects == effects;

  @override
  int get hashCode =>
      Object.hash(startSeconds, endSeconds, sourcePath, transitionAfterSeconds, transitionType, speedStart, speedEnd, effects);
}

String buildSegmentFilterGraph({
  required List<VideoSegment> segments,
  required List<int> sourceInputIndices,
  required double speed,
  required String videoFilters,
  required bool keepSourceAudio,
  bool useExternalAudio = false,
  int? externalAudioInputIndex,
}) {
  if (segments.isEmpty || speed <= 0) throw ArgumentError('Invalid segments.');
  if (sourceInputIndices.length != segments.length) {
    throw ArgumentError('Setiap segmen harus punya input video.');
  }
  final transitions = <int, double>{};
  for (var i = 0; i < segments.length - 1; i++) {
    final duration = segments[i].transitionAfterSeconds;
    if (duration < 0 || duration > 2) {
      throw ArgumentError('Durasi transisi harus 0–2 detik.');
    }
    if (duration > 0) {
      if (duration >= segments[i].endSeconds - segments[i].startSeconds ||
          duration >=
              segments[i + 1].endSeconds - segments[i + 1].startSeconds) {
        throw ArgumentError('Durasi transisi terlalu panjang.');
      }
      transitions[i] = duration / speed;
    }
  }
  final chains = <String>[];
  for (var i = 0; i < segments.length; i++) {
    final s = segments[i];
    final source = sourceInputIndices[i];
    final segmentSpeed = s.averageSpeed * speed;
    
    // Build per-segment filters from effects
    final segmentFilters = <String>[];
    for (final effect in s.effects) {
      segmentFilters.add(effect.toFFmpegFilter());
    }
    
    // Add global filters
    if (videoFilters.isNotEmpty) {
      segmentFilters.add(videoFilters);
    }
    
    final videoChain = <String>[
      'trim=start=${s.startSeconds}:end=${s.endSeconds}',
      'setpts=(PTS-STARTPTS)/$segmentSpeed',
      if (segmentFilters.isNotEmpty) segmentFilters.join(','),
    ].join(',');
    chains.add('[$source:v]$videoChain[v$i]');
    if (keepSourceAudio || useExternalAudio) {
      final audioSource = useExternalAudio
          ? '${externalAudioInputIndex ?? sourceInputIndices.length}:a'
          : '$source:a';
      chains.add(
          '[$audioSource]atrim=start=${s.startSeconds}:end=${s.endSeconds},asetpts=PTS-STARTPTS,atempo=$segmentSpeed[a$i]');
    }
  }
  final hasAudio = keepSourceAudio || useExternalAudio;
  final labels = <String>[];
  for (var i = 0; i < segments.length; i++) {
    labels.add('[v$i]');
    if (hasAudio) labels.add('[a$i]');
  }
  if (transitions.isEmpty) {
    chains.add(
        '${labels.join()}concat=n=${segments.length}:v=1:a=${hasAudio ? 1 : 0}[outv]${hasAudio ? '[outa]' : ''}');
    return chains.join(';');
  }
  for (var i = 0; i < segments.length; i++) {
    chains.add('[v$i]setpts=PTS-STARTPTS[vx$i]');
    if (hasAudio) chains.add('[a$i]asetpts=PTS-STARTPTS[ax$i]');
  }
  var lastVideo = 'vx0';
  String? lastAudio = hasAudio ? 'ax0' : null;
  var cumulative = segments[0].endSeconds / speed;
  for (var i = 0; i < segments.length - 1; i++) {
    final duration = transitions[i] ?? 0.0;
    final transitionType = segments[i].transitionType;
    if (duration == 0 || transitionType == TransitionType.none) {
      chains.add('[$lastVideo][vx${i + 1}]concat=n=2:v=1:a=0[vjoin$i]');
      lastVideo = 'vjoin$i';
      if (hasAudio) {
        chains.add('[$lastAudio][ax${i + 1}]concat=n=2:v=0:a=1[ajoin$i]');
        lastAudio = 'ajoin$i';
      }
      cumulative += segments[i + 1].endSeconds / speed;
      continue;
    }
    final offset = cumulative - duration;
    chains.add(
        '[$lastVideo][vx${i + 1}]xfade=transition=${transitionType.ffmpegName}:duration=$duration:offset=$offset[vjoin$i]');
    lastVideo = 'vjoin$i';
    if (hasAudio) {
      chains.add('[$lastAudio][ax${i + 1}]acrossfade=d=$duration[ajoin$i]');
      lastAudio = 'ajoin$i';
    }
    cumulative += segments[i + 1].endSeconds / speed - duration;
  }
  chains.add('[$lastVideo]null[outv]');
  if (hasAudio) chains.add('[$lastAudio]anull[outa]');
  return chains.join(';');
}

List<VideoSegment> splitVideoSegment(VideoSegment segment, double point) {
  if (point <= segment.startSeconds + .25 ||
      point >= segment.endSeconds - .25) {
    throw ArgumentError.value(point, 'point', 'Split must be inside segment.');
  }
  return [
    VideoSegment(
        startSeconds: segment.startSeconds,
        endSeconds: point,
        sourcePath: segment.sourcePath,
        transitionAfterSeconds: segment.transitionAfterSeconds),
    VideoSegment(
        startSeconds: point,
        endSeconds: segment.endSeconds,
        sourcePath: segment.sourcePath,
        transitionAfterSeconds: segment.transitionAfterSeconds),
  ];
}
