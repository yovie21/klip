enum OverlayType { image, text, shape }

class VideoOverlay {
  const VideoOverlay({
    required this.id,
    required this.type,
    required this.source, // file path for image, text content, or shape type
    this.startSeconds = 0,
    this.endSeconds = double.infinity,
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 100,
    this.opacity = 1.0,
    this.rotation = 0,
    this.zIndex = 0,
  });

  final String id;
  final OverlayType type;
  final String source;
  final double startSeconds;
  final double endSeconds;
  final double x; // percentage 0-100
  final double y; // percentage 0-100
  final double width; // percentage 0-100
  final double height; // percentage 0-100
  final double opacity; // 0-1
  final double rotation; // 0-360 degrees
  final int zIndex; // render order

  String toFFmpegOverlay() {
    // ponytail: overlay v1 supports image + text; add video overlays when needed.
    switch (type) {
      case OverlayType.image:
        return 'overlay=x=W*$x/100:y=H*$y/100:w=W*$width/100:h=H*$height/100:alpha=$opacity';
      case OverlayType.text:
        final escapedText = source.replaceAll("'", "\\'");
        return "drawtext=text='$escapedText':x=W*$x/100:y=H*$y/100:fontsize=20:fontcolor=white@$opacity";
      case OverlayType.shape:
        return 'drawbox=x=W*$x/100:y=H*$y/100:w=W*$width/100:h=H*$height/100:color=white@$opacity:thickness=2';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is VideoOverlay &&
      other.id == id &&
      other.type == type &&
      other.source == source &&
      other.startSeconds == startSeconds &&
      other.endSeconds == endSeconds &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.opacity == opacity &&
      other.rotation == rotation &&
      other.zIndex == zIndex;

  @override
  int get hashCode => Object.hashAll([
    id,
    type,
    source,
    startSeconds,
    endSeconds,
    x,
    y,
    width,
    height,
    opacity,
    rotation,
    zIndex,
  ]);
}
