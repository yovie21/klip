import 'video_segment.dart';

class VideoEditHistory {
  VideoEditHistory(List<VideoSegment> initial)
      : _states = [List.unmodifiable(initial)];

  final List<List<VideoSegment>> _states;
  int _index = 0;

  List<VideoSegment> get segments => _states[_index];
  bool get canUndo => _index > 0;
  bool get canRedo => _index < _states.length - 1;

  void split(int index, double point) {
    final splitParts = splitVideoSegment(segments[index], point);
    final next = [
      ...segments.take(index),
      ...splitParts,
      ...segments.skip(index + 1),
    ];
    _states.removeRange(_index + 1, _states.length);
    _states.add(List.unmodifiable(next));
    _index++;
  }

  void append(VideoSegment segment) {
    final next = [...segments, segment];
    _states.removeRange(_index + 1, _states.length);
    _states.add(List.unmodifiable(next));
    _index++;
  }

  void setTransition(int index, double seconds) {
    if (index < 0 || index >= segments.length - 1) {
      throw RangeError.index(index, segments, 'index');
    }
    if (seconds < 0 || seconds > 2) throw ArgumentError('Invalid duration.');
    final segment = segments[index];
    if (seconds >= segment.endSeconds - segment.startSeconds ||
        seconds >=
            segments[index + 1].endSeconds - segments[index + 1].startSeconds) {
      throw ArgumentError('Transition exceeds clip duration.');
    }
    final next = [...segments];
    next[index] = VideoSegment(
      startSeconds: segment.startSeconds,
      endSeconds: segment.endSeconds,
      sourcePath: segment.sourcePath,
      transitionAfterSeconds: seconds,
    );
    _states.removeRange(_index + 1, _states.length);
    _states.add(List.unmodifiable(next));
    _index++;
  }

  void delete(int index) {
    if (segments.length <= 1) {
      throw StateError('Tidak bisa menghapus satu-satunya klip.');
    }
    final next = [...segments]..removeAt(index);
    _states.removeRange(_index + 1, _states.length);
    _states.add(List.unmodifiable(next));
    _index++;
  }

  bool undo() {
    if (!canUndo) return false;
    _index--;
    return true;
  }

  bool redo() {
    if (!canRedo) return false;
    _index++;
    return true;
  }
}
