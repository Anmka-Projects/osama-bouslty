import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_theme_extension.dart';
import 'home_spot_video_player_sheet.dart';
import '../core/home/home_spot_video_utils.dart';

/// Two side-by-side home spot video tiles (replaces enrolled / hours stat cards).
class HomeSpotVideosRow extends StatelessWidget {
  const HomeSpotVideosRow({
    super.key,
    required this.videos,
  });

  final List<Map<String, dynamic>> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < videos.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _HomeSpotVideoSlot(video: videos[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class HomeSpotVideosRowSkeleton extends StatelessWidget {
  const HomeSpotVideosRowSkeleton({super.key});

  static const double _tileHeight = 104;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _skeletonTile(theme)),
          const SizedBox(width: 12),
          Expanded(child: _skeletonTile(theme)),
        ],
      ),
    );
  }

  Widget _skeletonTile(AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 12,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardMuted,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        Container(
          height: _tileHeight,
          decoration: BoxDecoration(
            color: theme.cardMuted,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ],
    );
  }
}

/// Optional [description] above the video tile (set from admin dashboard).
class _HomeSpotVideoSlot extends StatelessWidget {
  const _HomeSpotVideoSlot({required this.video});

  final Map<String, dynamic> video;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeExtension.of(context);
    final description = video['description']?.toString().trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (description.isNotEmpty) ...[
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.readexPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.foreground,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _HomeSpotVideoTile(video: video),
      ],
    );
  }
}

class _HomeSpotVideoTile extends StatelessWidget {
  const _HomeSpotVideoTile({required this.video});

  final Map<String, dynamic> video;

  static const double _tileHeight = 104;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeExtension.of(context);
    final thumbnail = video['thumbnail']?.toString() ?? '';
    final title = video['title']?.toString() ?? '';
    final source = parseHomeSpotVideoSource(video);
    final canPlay = source.hasSource;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: canPlay
            ? () => HomeSpotVideoPlayerSheet.show(context, video: video)
            : null,
        child: Container(
          height: _tileHeight,
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: theme.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail.isNotEmpty)
                Image.network(
                  thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(theme),
                )
              else
                _placeholder(theme),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navyDeep.withOpacity(0.2),
                      AppColors.navyDeep.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.brandWhite.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navyDeep.withOpacity(0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          canPlay
                              ? Icons.play_arrow_rounded
                              : Icons.videocam_off,
                          color: theme.icon,
                          size: 28,
                        ),
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.readexPro(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandWhite,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: AppColors.navyDeep.withOpacity(0.54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(AppThemeExtension theme) {
    return Container(
      color: theme.progressTrack,
      alignment: Alignment.center,
      child: Icon(
        Icons.play_circle_outline_rounded,
        size: 40,
        color: theme.icon.withOpacity(0.45),
      ),
    );
  }
}
