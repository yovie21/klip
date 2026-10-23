import 'package:flutter_test/flutter_test.dart';
import 'package:klip/features/editor/domain/video_segment.dart';

void main() {
  test('split preserves the full source duration in two ordered segments', () {
    final segments = splitVideoSegment(
      const VideoSegment(startSeconds: 0, endSeconds: 8),
      3.25,
    );
    expect(segments, const [
      VideoSegment(startSeconds: 0, endSeconds: 3.25),
      VideoSegment(startSeconds: 3.25, endSeconds: 8),
    ]);
    expect(segments.last.endSeconds - segments.first.startSeconds, 8);
  });

  test('builds joined FFmpeg branches for two split ranges', () {
    final graph = buildSegmentFilterGraph(
      segments: const [
        VideoSegment(startSeconds: 0, endSeconds: 3.25),
        VideoSegment(startSeconds: 3.25, endSeconds: 8),
      ],
      sourceInputIndices: const [0, 0],
      speed: 1,
      videoFilters: '',
      keepSourceAudio: true,
    );
    expect(graph, contains('concat=n=2:v=1:a=1[outv][outa]'));
    expect(graph, contains('trim=start=3.25:end=8'));
    expect(graph, contains('[0:a]atrim=start=3.25:end=8'));
  });

  test('multi-source segments map to distinct FFmpeg inputs', () {
    final graph = buildSegmentFilterGraph(
      segments: const [
        VideoSegment(startSeconds: 0, endSeconds: 7, sourcePath: '/one.mp4'),
        VideoSegment(startSeconds: 0, endSeconds: 5, sourcePath: '/two.mp4'),
      ],
      sourceInputIndices: const [0, 1],
      speed: 1,
      videoFilters: '',
      keepSourceAudio: false,
    );
    expect(graph, contains('[0:v]trim=start=0.0:end=7.0'));
    expect(graph, contains('[1:v]trim=start=0.0:end=5.0'));
    expect(graph, contains('concat=n=2:v=1:a=0[outv]'));
  });

  test('transition uses xfade and audio crossfade between clips', () {
    final graph = buildSegmentFilterGraph(
      segments: const [
        VideoSegment(startSeconds: 0, endSeconds: 5, transitionAfterSeconds: 1),
        VideoSegment(startSeconds: 0, endSeconds: 4),
      ],
      sourceInputIndices: const [0, 1],
      speed: 1,
      videoFilters: '',
      keepSourceAudio: true,
    );
    expect(graph, contains('xfade=transition=fade:duration=1.0:offset=4.0'));
    expect(graph, contains('acrossfade=d=1.0'));
  });

  test('rejects transition longer than either clip', () {
    expect(
      () => buildSegmentFilterGraph(
        segments: const [
          VideoSegment(
              startSeconds: 0, endSeconds: 1, transitionAfterSeconds: 1),
          VideoSegment(startSeconds: 0, endSeconds: 3),
        ],
        sourceInputIndices: const [0, 1],
        speed: 1,
        videoFilters: '',
        keepSourceAudio: false,
      ),
      throwsArgumentError,
    );
  });

  test('rejects splits too close to either edge', () {
    expect(
      () => splitVideoSegment(
        const VideoSegment(startSeconds: 0, endSeconds: 8),
        .1,
      ),
      throwsArgumentError,
    );
  });
}
