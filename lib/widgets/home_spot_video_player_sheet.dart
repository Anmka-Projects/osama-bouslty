import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pod_player/pod_player.dart';
import '../services/token_storage_service.dart';
import '../core/home/home_spot_video_utils.dart';

/// Full-width player sheet for a home spot video.
class HomeSpotVideoPlayerSheet extends StatefulWidget {
  const HomeSpotVideoPlayerSheet({
    super.key,
    required this.video,
  });

  final Map<String, dynamic> video;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> video,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: HomeSpotVideoPlayerSheet(video: video),
      ),
    );
  }

  @override
  State<HomeSpotVideoPlayerSheet> createState() =>
      _HomeSpotVideoPlayerSheetState();
}

class _HomeSpotVideoPlayerSheetState extends State<HomeSpotVideoPlayerSheet> {
  PodPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final source = parseHomeSpotVideoSource(widget.video);
    if (!source.hasSource) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No video source';
        });
      }
      return;
    }

    try {
      if (source.youtubeWatchUrl != null) {
        _controller = PodPlayerController(
          playVideoFrom: PlayVideoFrom.youtube(source.youtubeWatchUrl!),
          podPlayerConfig: const PodPlayerConfig(
            autoPlay: true,
            isLooping: false,
          ),
        );
      } else {
        var url = source.directUrl!;
        final token = await TokenStorageService.instance.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final uri = Uri.parse(url);
          url = uri.replace(queryParameters: {
            ...uri.queryParameters,
            'token': token,
          }).toString();
        }
        _controller = PodPlayerController(
          playVideoFrom: PlayVideoFrom.network(url),
          podPlayerConfig: const PodPlayerConfig(
            autoPlay: true,
            isLooping: false,
          ),
        );
      }

      await _controller!.initialise();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.video['title']?.toString().trim() ?? '';
    final description = widget.video['description']?.toString().trim() ?? '';
    final hasHeader = title.isNotEmpty || description.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (title.isNotEmpty)
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.readexPro(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (description.isNotEmpty) ...[
                          if (title.isNotEmpty) const SizedBox(height: 4),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.readexPro(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.35,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.readexPro(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : _controller != null
                        ? PodVideoPlayer(
                            controller: _controller!,
                            alwaysShowProgressBar: true,
                          )
                        : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
