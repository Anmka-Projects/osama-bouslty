/// Parses home spot video payload from API into playable sources.
class HomeSpotVideoSource {
  const HomeSpotVideoSource({
    this.youtubeWatchUrl,
    this.directUrl,
  });

  final String? youtubeWatchUrl;
  final String? directUrl;

  bool get hasSource =>
      (youtubeWatchUrl != null && youtubeWatchUrl!.isNotEmpty) ||
      (directUrl != null && directUrl!.isNotEmpty);
}

String? _clean(String? value) {
  final v = value?.trim();
  if (v == null || v.isEmpty) return null;
  return v;
}

String? _youtubeIdFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    return _clean(id);
  }
  if (uri.host.contains('youtube.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    if (uri.pathSegments.contains('embed') && uri.pathSegments.length > 1) {
      final idx = uri.pathSegments.indexOf('embed');
      if (idx + 1 < uri.pathSegments.length) {
        return uri.pathSegments[idx + 1];
      }
    }
  }
  return null;
}

HomeSpotVideoSource parseHomeSpotVideoSource(Map<String, dynamic> item) {
  String? youtubeId = _clean(item['youtube_id']?.toString()) ??
      _clean(item['youtubeVideoId']?.toString());

  String? directUrl = _clean(item['video_url']?.toString()) ??
      _clean(item['videoUrl']?.toString());

  if (item['video'] is Map) {
    final video = item['video'] as Map;
    youtubeId ??= _clean(video['youtube_id']?.toString());
    directUrl ??= _clean(video['url']?.toString());
  }

  final rawUrl = _clean(item['url']?.toString());
  if (rawUrl != null) {
    if (rawUrl.contains('youtube.com') || rawUrl.contains('youtu.be')) {
      youtubeId ??= _youtubeIdFromUrl(rawUrl);
    } else {
      directUrl ??= rawUrl;
    }
  }

  if (directUrl != null &&
      (directUrl.contains('youtube.com') || directUrl.contains('youtu.be'))) {
    youtubeId ??= _youtubeIdFromUrl(directUrl);
    directUrl = null;
  }

  String? youtubeWatchUrl;
  if (youtubeId != null) {
    youtubeWatchUrl = 'https://www.youtube.com/watch?v=$youtubeId';
  }

  return HomeSpotVideoSource(
    youtubeWatchUrl: youtubeWatchUrl,
    directUrl: directUrl,
  );
}

List<Map<String, dynamic>> normalizeHomeSpotVideos(dynamic raw) {
  if (raw is! List) return [];
  final items = raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .where((m) => m['is_active'] != false)
      .toList();

  items.sort((a, b) {
    final slotA = a['slot'] is int
        ? a['slot'] as int
        : int.tryParse('${a['slot']}') ?? 999;
    final slotB = b['slot'] is int
        ? b['slot'] as int
        : int.tryParse('${b['slot']}') ?? 999;
    final cmp = slotA.compareTo(slotB);
    if (cmp != 0) return cmp;
    final orderA = a['sort_order'] is int
        ? a['sort_order'] as int
        : int.tryParse('${a['sort_order']}') ?? 0;
    final orderB = b['sort_order'] is int
        ? b['sort_order'] as int
        : int.tryParse('${b['sort_order']}') ?? 0;
    return orderA.compareTo(orderB);
  });

  return items.take(2).toList();
}
