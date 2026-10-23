import 'package:flutter_test/flutter_test.dart';
import 'package:klip/features/editor/domain/video_edit_history.dart';
import 'package:klip/features/editor/domain/video_segment.dart';

void main() {
  test('undo and redo restore split timeline snapshots', () {
    final history = VideoEditHistory(
      const [VideoSegment(startSeconds: 0, endSeconds: 8)],
    );
    history.split(0, 3);
    expect(history.segments, const [
      VideoSegment(startSeconds: 0, endSeconds: 3),
      VideoSegment(startSeconds: 3, endSeconds: 8),
    ]);
    expect(history.undo(), isTrue);
    expect(
        history.segments, const [VideoSegment(startSeconds: 0, endSeconds: 8)]);
    expect(history.redo(), isTrue);
    expect(history.segments, const [
      VideoSegment(startSeconds: 0, endSeconds: 3),
      VideoSegment(startSeconds: 3, endSeconds: 8),
    ]);
  });

  test('new edit after undo discards redo branch', () {
    final history = VideoEditHistory(
      const [VideoSegment(startSeconds: 0, endSeconds: 8)],
    );
    history.split(0, 3);
    history.undo();
    history.split(0, 5);
    expect(history.redo(), isFalse);
    expect(history.segments.last.endSeconds, 8);
    expect(history.segments.first.endSeconds, 5);
  });

  test('append adds clip and undo removes it', () {
    final history = VideoEditHistory(const [
      VideoSegment(startSeconds: 0, endSeconds: 7, sourcePath: '/one.mp4'),
    ]);
    history.append(const VideoSegment(
        startSeconds: 0, endSeconds: 5, sourcePath: '/two.mp4'));
    expect(history.segments.length, 2);
    expect(history.segments.last.sourcePath, '/two.mp4');
    expect(history.undo(), isTrue);
    expect(history.segments.length, 1);
    expect(history.segments.single.sourcePath, '/one.mp4');
  });

  test('delete removes selected segment and undo restores it', () {
    final history = VideoEditHistory(const [
      VideoSegment(startSeconds: 0, endSeconds: 3),
      VideoSegment(startSeconds: 3, endSeconds: 8),
    ]);
    history.delete(0);
    expect(
        history.segments, const [VideoSegment(startSeconds: 3, endSeconds: 8)]);
    expect(history.undo(), isTrue);
    expect(history.segments.length, 2);
  });

  test('cannot delete the final segment', () {
    final history = VideoEditHistory(
      const [VideoSegment(startSeconds: 0, endSeconds: 8)],
    );
    expect(() => history.delete(0), throwsStateError);
  });
}
