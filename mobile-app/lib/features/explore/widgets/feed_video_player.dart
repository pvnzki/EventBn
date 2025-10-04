import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final double? aspectRatio;

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = false; // Start with controls hidden
  String? _errorMessage;

  // Timer to auto-hide controls
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      print('🎥 Initializing video player for: ${widget.videoUrl}');

      // Validate URL format
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      if (!widget.videoUrl.startsWith('http')) {
        throw Exception('Invalid video URL format: ${widget.videoUrl}');
      }

      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        if (widget.autoPlay) {
          _controller
              .setVolume(0.0); // Start muted for autoplay (common UX pattern)
          _controller.play();
          print('🎥 Video started autoplaying (muted)');
        }

        print(
            '✅ Video player initialized successfully for: ${widget.videoUrl}');
      }
    } catch (e) {
      print('❌ Error initializing video player for ${widget.videoUrl}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    print(
        '🎬 [VideoPlayer] Toggle play/pause - Current state: isPlaying=${_controller.value.isPlaying}');
    if (_controller.value.isPlaying) {
      _controller.pause();
      print('🎬 [VideoPlayer] Video paused');
    } else {
      _controller.play();
      print('🎬 [VideoPlayer] Video started playing');
    }
    _onControlTap(); // Reset timer when control is used
    setState(() {});
  }

  void _toggleVolume() {
    print(
        '🎬 [VideoPlayer] Toggle volume - Current volume: ${_controller.value.volume}');
    if (_controller.value.volume > 0) {
      _controller.setVolume(0.0);
      print('🎬 [VideoPlayer] Video muted');
    } else {
      _controller.setVolume(1.0);
      print('🎬 [VideoPlayer] Video unmuted');
    }
    _onControlTap(); // Reset timer when control is used
    setState(() {});
  }

  void _toggleControls() {
    print(
        '🎬 [VideoPlayer] Toggling controls visibility: $_showControls -> ${!_showControls}');
    setState(() {
      _showControls = !_showControls;
    });

    // Auto-hide controls after 3 seconds if they're showing
    if (_showControls) {
      _resetControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
        print('🎬 [VideoPlayer] Auto-hiding controls');
      }
    });
  }

  void _onControlTap() {
    // When user interacts with controls, reset the timer
    if (_showControls) {
      _resetControlsTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 8),
            const Text(
              'Error loading video',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black87,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.showControls ? _toggleControls : null,
      child: Container(
        width: double.infinity,
        height: widget.aspectRatio != null ? null : 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio ?? _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),

                // Controls overlay
                if (_showControls && widget.showControls)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top controls area (can be used for other controls if needed)
                        Container(),

                        // Center control buttons (Instagram style)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mute/Unmute button
                            GestureDetector(
                              onTap: _toggleVolume,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Icon(
                                  _controller.value.volume > 0
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Play/Pause button
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ],
                        ), // Bottom controls
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text(
                                _formatDuration(_controller.value.position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.blue,
                                    bufferedColor: Colors.grey,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(_controller.value.duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Loading indicator during buffering
                if (_controller.value.isBuffering)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
