import 'video_segment.dart';

// Extension untuk VideoSegment untuk duplicate, reverse, freeze
extension VideoSegmentActions on VideoSegment {
  // Duplicate segment dengan metadata
  VideoSegment duplicate() => VideoSegment(
        startSeconds: startSeconds,
        endSeconds: endSeconds,
        sourcePath: sourcePath,
        transitionType: transitionType,
        transitionAfterSeconds: transitionAfterSeconds,
        speedStart: speedStart,
        speedEnd: speedEnd,
        effects: List.of(effects),
      );

  // Reverse playback
  VideoSegment reverse() => VideoSegment(
        startSeconds: startSeconds,
        endSeconds: endSeconds,
        sourcePath: sourcePath,
        transitionType: transitionType,
        transitionAfterSeconds: transitionAfterSeconds,
        speedStart: speedEnd,
        speedEnd: speedStart,
        effects: List.of(effects),
        // Ponytail: actual reverse video decode = upgrade (use ffmpeg reverse filter)
      );

  // Freeze frame di start atau end
  VideoSegment freezeFrame({required bool atStart}) =>
      VideoSegment(
        startSeconds: startSeconds,
        endSeconds: endSeconds,
        sourcePath: sourcePath,
        transitionType: transitionType,
        transitionAfterSeconds: transitionAfterSeconds,
        speedStart: atStart ? 0 : speedStart,
        speedEnd: atStart ? speedStart : 0,
        effects: List.of(effects),
        // Ponytail: render frozen frame di FFmpeg = fps=1
      );
}
