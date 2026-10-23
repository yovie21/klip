import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../domain/video_segment.dart';
import '../domain/video_effect.dart';

class RealtimePreviewWidget extends StatefulWidget {
  const RealtimePreviewWidget({
    super.key,
    required this.videoPath,
    required this.segment,
    required this.effects,
  });

  final String videoPath;
  final VideoSegment segment;
  final List<VideoEffect> effects;

  @override
  State<RealtimePreviewWidget> createState() => _RealtimePreviewWidgetState();
}

class _RealtimePreviewWidgetState extends State<RealtimePreviewWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(
        File(widget.videoPath),
      )..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.seekTo(
          Duration(seconds: widget.segment.startSeconds.toInt()),
        );
        _controller.play();
      });
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.black,
            height: 200,
            width: double.infinity,
            child: _isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (widget.effects.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.effects.length} effects',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      Center(
                        child: IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Segment: ${widget.segment.startSeconds.toStringAsFixed(1)}s - ${widget.segment.endSeconds.toStringAsFixed(1)}s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (widget.effects.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Effects:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: List.generate(
                          widget.effects.length,
                          (i) => Chip(
                            label: Text(widget.effects[i].type.displayName),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'No effects applied',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
