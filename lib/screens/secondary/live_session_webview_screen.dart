import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/design/app_theme_context.dart';
import '../../l10n/app_localizations.dart';

/// In-app WebView for live session links (Zoom, Google Meet, Teams…).
/// Non-http(s) deep links (e.g. zoommtg://) are handed off to the system.
class LiveSessionWebViewScreen extends StatefulWidget {
  const LiveSessionWebViewScreen({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<LiveSessionWebViewScreen> createState() =>
      _LiveSessionWebViewScreenState();
}

class _LiveSessionWebViewScreenState extends State<LiveSessionWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _hasError = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _hasError = true);
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.isScheme('http') || uri.isScheme('https')) {
              return NavigationDecision.navigate;
            }
            // zoommtg://, tel:, mailto: and friends -> hand to the OS.
            _openExternally(uri);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _openExternally(Uri uri) {
    launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
      // No app installed that can handle this scheme — stay on the WebView.
      return false;
    });
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = context.appTheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.card,
        foregroundColor: theme.foreground,
        elevation: 0,
        title: Text(
          widget.title?.isNotEmpty == true ? widget.title! : l10n.liveSession,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => _openExternally(Uri.parse(widget.url)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100 && !_hasError)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2,
              backgroundColor: theme.cardMuted,
              color: theme.icon,
            ),
          Expanded(
            child: _hasError
                ? _buildErrorState(l10n)
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: context.appTheme.iconMuted,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.liveSessionOpenLinkFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.cardTitle,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
