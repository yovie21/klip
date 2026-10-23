/// FFmpeg xfade transition types.
enum TransitionType {
  none('none', 'Tidak ada'),
  fade('fade', 'Fade'),
  slideLeft('slideleft', 'Geser Kiri'),
  slideRight('slideright', 'Geser Kanan'),
  slideUp('slideup', 'Geser Atas'),
  slideDown('slidedown', 'Geser Bawah'),
  zoomInQuad('zoom', 'Zoom In'),
  wipeLeft('wipeLeft', 'Wipe Kiri'),
  wipeRight('wipeRight', 'Wipe Kanan'),
  circleOpen('circleopen', 'Lingkaran Buka'),
  circleClosed('circleclosed', 'Lingkaran Tutup'),
  vopen('vopen', 'V Buka'),
  vclose('vclose', 'V Tutup'),
  hopen('hopen', 'H Buka'),
  hclose('hclose', 'H Tutup'),
  push('push', 'Push'),
  squeeze('squeeze', 'Squeeze'),
  dissolve('dissolve', 'Dissolve');

  const TransitionType(this.ffmpegName, this.label);

  final String ffmpegName;
  final String label;

  static TransitionType? tryParse(String? name) =>
      values.cast<TransitionType?>().firstWhere(
            (t) => t?.name == name,
            orElse: () => null,
          );
}
