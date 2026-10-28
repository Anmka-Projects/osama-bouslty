import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_theme_context.dart';

class DownloadedVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String videoTitle;

  const DownloadedVideoPlayer({
    super.key,
    required this.videoPath,
    required this.videoTitle,
  });

  @override
  State<DownloadedVideoPlayer> createState() => _DownloadedVideoPlayerState();
}

class _DownloadedVideoPlayerState extends State<DownloadedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeVideo();
  }

  void _initializeVideo() {
    print('Initializing video player with path: ${widget.videoPath}');

    final file = File(widget.videoPath);
    if (!file.existsSync()) {
      print('Video file does not exist: ${widget.videoPath}');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ملف الفيديو غير موجود',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final fileSize = file.lengthSync();
      final ext = widget.videoPath.split('.').last.toLowerCase();
      print('Local video file details -> size: $fileSize bytes, ext: .$ext');
      if (fileSize < 1024) {
        print(
            '⚠️ Video file is very small (<1KB). It might be an HTML/JSON error page, not a real video file.');
      }
    } catch (e) {
      print('Error reading video file info: $e');
    }

    _controller = VideoPlayerController.file(file);

    _controller!.initialize().then((_) {
      print('Video controller initialized successfully');
      if (!mounted) return;
      _controller!.addListener(() {
        if (mounted && _showControls) setState(() {});
      });
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
    }).catchError((error) {
      print('Error initializing video controller: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تحميل الفيديو: $error',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  Widget _buildVideoSurface() {
    final controller = _controller!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = controller.value.aspectRatio;
        if (aspectRatio <= 0 || !constraints.hasBoundedWidth) {
          return const ColoredBox(color: Colors.black);
        }

        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final screenAspect = screenWidth / screenHeight;

        // Always fit the full frame (contain) — no zoom/crop in any orientation.
        final double width;
        final double height;
        if (screenAspect > aspectRatio) {
          height = screenHeight;
          width = screenHeight * aspectRatio;
        } else {
          width = screenWidth;
          height = screenWidth / aspectRatio;
        }

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: VideoPlayer(controller),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(context.appTheme.icon),
              ),
            )
          : _controller != null && _controller!.value.isInitialized
              ? GestureDetector(
                  onTap: () {
                    setState(() => _showControls = !_showControls);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildVideoSurface(),

                      if (_showControls) ...[
                        // Dim overlay
                        Container(color: Colors.black.withOpacity(0.28)),

                        // Top bar (overlay — does not push video down)
                        SafeArea(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.videoTitle,
                                      style: GoogleFonts.readexPro(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Center play/pause
                        Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _togglePlay,
                              customBorder: const CircleBorder(),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.appTheme.icon,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom controls
                        SafeArea(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VideoProgressIndicator(
                                    _controller!,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: context.appTheme.icon,
                                      bufferedColor: Colors.white54,
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _togglePlay,
                                        icon: Icon(
                                          _isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                                          style: GoogleFonts.readexPro(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      PopupMenuButton<double>(
                                        icon: const Icon(
                                          Icons.speed,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 0.5,
                                            child: Text('0.5x'),
                                          ),
                                          PopupMenuItem(
                                            value: 0.75,
                                            child: Text('0.75x'),
                                          ),
                                          PopupMenuItem(
                                            value: 1.0,
                                            child: Text('1x'),
                                          ),
                                          PopupMenuItem(
                                            value: 1.25,
                                            child: Text('1.25x'),
                                          ),
                                          PopupMenuItem(
                                            value: 1.5,
                                            child: Text('1.5x'),
                                          ),
                                          PopupMenuItem(
                                            value: 2.0,
                                            child: Text('2x'),
                                          ),
                                        ],
                                        onSelected: (speed) {
                                          _controller!
                                              .setPlaybackSpeed(speed);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'خطأ في تحميل الفيديو',
                        style: GoogleFonts.readexPro(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مسار الفيديو: ${widget.videoPath}',
                        style: GoogleFonts.readexPro(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: Text(
                          'رجوع',
                          style: GoogleFonts.readexPro(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appTheme.icon,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
