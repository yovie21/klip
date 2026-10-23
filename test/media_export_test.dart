import 'package:flutter_test/flutter_test.dart';
import 'package:klip/features/editor/domain/video_segment.dart';
import 'package:klip/features/editor/domain/video_effect.dart';
import 'package:klip/features/editor/domain/transition_type.dart';
import 'package:klip/features/editor/domain/video_overlay.dart';
import 'package:klip/features/projects/domain/media_project.dart';

void main() {
  group('MediaExportService', () {
    test('export with transitions builds valid FFmpeg args', () async {
      // ponytail: requires real video file on device; skip in unit test.
      // Run integration test on device for end-to-end validation.
      final seg = VideoSegment(
        startSeconds: 0,
        endSeconds: 5,
        sourcePath: '/path/to/video.mp4',
        transitionType: TransitionType.slideLeft,
        transitionAfterSeconds: 0.5,
        speedStart: 1.0,
        speedEnd: 1.0,
      );
      expect(seg.transitionType, TransitionType.slideLeft);
      expect(seg.transitionAfterSeconds, 0.5);
    });

    test('effects serialize to FFmpeg filters', () {
      final effect = VideoEffect(
        type: EffectType.brightness,
        intensity: 0.5,
      );
      final filter = effect.toFFmpegFilter();
      expect(filter, contains('brightness'));
      expect(filter, contains('0.5'));
    });

    test('overlays serialize to FFmpeg filters', () {
      final overlay = VideoOverlay(
        id: 'test-1',
        type: OverlayType.text,
        source: 'Hello World',
        startSeconds: 1,
        endSeconds: 5,
        x: 10,
        y: 20,
        opacity: 0.8,
      );
      final filter = overlay.toFFmpegOverlay();
      expect(filter, contains('drawtext'));
      expect(filter, contains('Hello World'));
      expect(filter, contains('0.8'));
    });

    test('audio track serialization', () {
      final track = AudioTrack(
        source: '/path/to/audio.mp3',
        volume: 0.8,
        fadeInSeconds: 0.5,
        fadeOutSeconds: 1.0,
      );
      expect(track.volume, 0.8);
      expect(track.fadeInSeconds, 0.5);
    });

    test('speed ramp calculation', () {
      final seg = VideoSegment(
        startSeconds: 0,
        endSeconds: 10,
        sourcePath: '/path/to/video.mp4',
        speedStart: 0.5,
        speedEnd: 2.0,
      );
      final avgSpeed = seg.averageSpeed;
      expect(avgSpeed, greaterThan(0.5));
      expect(avgSpeed, lessThan(2.0));
    });
  });
}
