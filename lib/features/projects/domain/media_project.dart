import '../../../features/editor/domain/video_effect.dart';
import '../../../features/editor/domain/video_overlay.dart';

class MediaProject {
  MediaProject(
    this.name,
    this.clips, {
    this.effects = const [],
    this.audioTracks = const [],
    this.overlays = const [],
  });

  final String name;
  final List<String> clips;
  final List<VideoEffect> effects;
  final List<AudioTrack> audioTracks;
  final List<VideoOverlay> overlays;
}

class AudioTrack {
  const AudioTrack({
    required this.source,
    this.volume = 1.0,
    this.startSeconds = 0,
    this.fadeInSeconds = 0,
    this.fadeOutSeconds = 0,
  });

  final String source; // file path
  final double volume; // 0.0 - 1.0
  final double startSeconds;
  final double fadeInSeconds;
  final double fadeOutSeconds;

  @override
  bool operator ==(Object other) =>
      other is AudioTrack &&
      other.source == source &&
      other.volume == volume &&
      other.startSeconds == startSeconds &&
      other.fadeInSeconds == fadeInSeconds &&
      other.fadeOutSeconds == fadeOutSeconds;

  @override
  int get hashCode =>
      Object.hash(source, volume, startSeconds, fadeInSeconds, fadeOutSeconds);
}
