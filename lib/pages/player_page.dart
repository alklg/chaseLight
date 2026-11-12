import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/drama.dart';
import '../models/media_source.dart';
import '../services/rule_engine.dart';
import '../services/store.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 注入到网页里的嗅探脚本：挂钩 fetch / XHR / media.src，抓到 m3u8、mp4 就回传。
const kSniffScript = r'''
(function () {
  if (window.__zgSniff) return;
  window.__zgSniff = 1;
  function send(u) {
    try {
      if (!u || typeof u !== 'string') return;
      if (u.indexOf('blob:') === 0) return;
      if (!/\.(m3u8|mp4|flv|mpd)(\?|#|$)/i.test(u)) return;
      window.ZgSnoop.postMessage(u);
    } catch (e) {}
  }
  var of = window.fetch;
  if (of) {
    window.fetch = function (input) {
      try { send(typeof input === 'string' ? input : (input && input.url)); } catch (e) {}
      return of.apply(this, arguments);
    };
  }
  var xo = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
    try { send(url && url.toString()); } catch (e) {}
    return xo.apply(this, arguments);
  };
  try {
    var desc = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
    if (desc && desc.set) {
      Object.defineProperty(HTMLMediaElement.prototype, 'src', {
        configurable: true,
        get: desc.get,
        set: function (v) { try { send(v && v.toString()); } catch (e) {} return desc.set.call(this, v); }
      });
    }
  } catch (e) {}
  var setAttr = Element.prototype.setAttribute;
  Element.prototype.setAttribute = function (k, v) {
    try { if (k === 'src') send(v && v.toString()); } catch (e) {}
    return setAttr.apply(this, arguments);
  };
  document.addEventListener('DOMContentLoaded', function () {
    try {
      document.querySelectorAll('video, source').forEach(function (el) {
        send(el.src || el.getAttribute('src'));
      });
    } catch (e) {}
  });
})();
''';

enum _Phase { sniffing, starting, playing, failed }

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.source,
    required this.detail,
    required this.episode,
    this.webOnly = false,
  });

  final MediaSource source;
  final DramaDetail detail;
  final Episode episode;

  /// 强制走网页模式（详情页抓取失败时的兜底入口）
  final bool webOnly;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final _engine = SourceRuleEngine();
  final _sniffed = <String>{};
  late final AppStore _store;

  WebViewController? _web;
  VideoPlayerController? _video;
  _Phase _phase = _Phase.sniffing;
  String _currentUrl = '';
  String? _error;
  bool _injected = false;
  bool _starting = false;
  bool _recordRestored = false;
  DateTime _lastSaved = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _store = context.read<AppStore>();
    _currentUrl = widget.episode.url;
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _boot();
  }

  @override
  void dispose() {
    _saveProgress(force: true);
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _engine.dispose();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _boot() async {
    if (!widget.webOnly && widget.source.play.isDirect) {
      try {
        final url = await _engine.directPlayUrl(
          widget.source,
          widget.episode.url,
        );
        if (url != null && await _startVideo(url)) return;
      } catch (_) {
        // 抓直链失败就退回网页嗅探
      }
    }
    if (!mounted) return;
    _startWeb();
  }

  void _startWeb() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('ZgSnoop', onMessageReceived: _onSniffed)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _currentUrl = url;
            _injected = false;
          },
          onProgress: (_) {
            if (!_injected) _inject();
          },
          onPageFinished: (_) {
            if (!_injected) _inject();
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? false) {
              setState(() {
                _phase = _Phase.failed;
                _error = '网页加载失败：${e.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(widget.episode.url),
        headers: widget.source.headers,
      );

    setState(() {
      _web = controller;
      _phase = _Phase.sniffing;
    });
  }

  Future<void> _inject() async {
    _injected = true;
    try {
      await _web?.runJavaScript(kSniffScript);
    } catch (_) {
      _injected = false;
    }
  }

  void _onSniffed(JavaScriptMessage message) {
    final raw = message.message.trim();
    if (raw.isEmpty || _sniffed.contains(raw)) return;
    _sniffed.add(raw);

    var resolved = raw;
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      try {
        resolved = Uri.parse(_currentUrl).resolve(raw).toString();
      } catch (_) {
        return;
      }
    }
    if (_phase == _Phase.sniffing) _startVideo(resolved);
  }

  Future<bool> _startVideo(String url) async {
    if (_starting) return false;
    _starting = true;
    setState(() {
      _phase = _Phase.starting;
      _error = null;
    });

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: {
        'User-Agent': kDefaultUserAgent,
        'Referer': widget.episode.url,
        ...widget.source.headers,
      },
    );

    try {
      await controller.initialize().timeout(const Duration(seconds: 20));
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return false;
      }
      controller.addListener(_onVideoTick);
      setState(() {
        _video = controller;
        _phase = _Phase.playing;
      });
      _restoreProgress();
      _saveProgress(force: true);
      _starting = false;
      return true;
    } catch (e) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _phase = _web != null ? _Phase.sniffing : _Phase.failed;
          if (_web == null) _error = '播放失败：$e';
        });
      }
      _starting = false;
      return false;
    }
  }

  void _restoreProgress() {
    if (_recordRestored) return;
    _recordRestored = true;
    final record = _store.findWatch(widget.source.id, widget.detail.pageUrl);
    if (record != null && record.episodeName == widget.episode.name) {
      final pos = record.position;
      if (pos.inSeconds > 5) _video?.seekTo(pos);
    }
  }

  void _onVideoTick() {
    final v = _video?.value;
    if (v == null || !v.isInitialized) return;
    final now = DateTime.now();
    if (now.difference(_lastSaved) < const Duration(seconds: 8)) return;
    _lastSaved = now;
    _saveProgress();
  }

  void _saveProgress({bool force = false}) {
    final v = _video?.value;
    if (v == null || !v.isInitialized) return;
    if (!force && v.position.inSeconds < 3) return;
    final prev = _store.findWatch(widget.source.id, widget.detail.pageUrl);
    _store.upsertWatch(
      WatchRecord(
        sourceId: widget.source.id,
        sourceName: widget.source.name,
        title: widget.detail.title,
        detailUrl: widget.detail.pageUrl,
        cover: prev?.cover ?? widget.detail.cover,
        episodeName: widget.episode.name,
        episodeUrl: widget.episode.url,
        position: v.position,
        duration: v.duration,
        totalEpisodes: widget.detail.episodes.length,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _body()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              title: widget.detail.title,
              episode: widget.episode.name,
              onBack: () => Navigator.maybePop(context),
            ),
          ),
          if (_phase == _Phase.sniffing)
            const Positioned(left: 0, right: 0, bottom: 0, child: _SniffHint()),
        ],
      ),
    );
  }

  Widget _body() {
    final t = L.of(context)!;
    switch (_phase) {
      case _Phase.playing:
        return _VideoView(controller: _video!);
      case _Phase.starting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                t.preparePlaying,
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ],
          ),
        );
      case _Phase.failed:
        return _FailedView(
          error: _error ?? t.somethingWrong,
          onRetry: () {
            setState(() {
              _phase = _Phase.sniffing;
              _error = null;
              _injected = false;
            });
            if (_web != null) {
              _inject();
            } else {
              _startWeb();
            }
          },
        );
      case _Phase.sniffing:
        final web = _web;
        if (web == null) {
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        }
        return WebViewWidget(controller: web);
    }
  }
}

class _VideoView extends StatefulWidget {
  const _VideoView({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_controlsVisible) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final v = widget.controller.value;

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: (v.aspectRatio.isFinite && v.aspectRatio > 0)
                ? v.aspectRatio
                : 16 / 9,
            child: VideoPlayer(widget.controller),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: AnimatedOpacity(
            opacity: _controlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color: Colors.black.withValues(
                alpha: _controlsVisible ? 0.25 : 0,
              ),
              child: Stack(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        final playing = widget.controller.value.isPlaying;
                        playing
                            ? widget.controller.pause()
                            : widget.controller.play();
                        setState(() {});
                        _scheduleHide();
                      },
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          v.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _Controls(controller: widget.controller),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xCC000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            colors: VideoProgressColors(
              playedColor: AppColors.primary,
              bufferedColor: Color(0x66FFFFFF),
              backgroundColor: Color(0x33FFFFFF),
            ),
          ),
          Row(
            children: [
              Text(
                _fmt(controller.value.position),
                style: const TextStyle(fontSize: 11.5, color: Colors.white70),
              ),
              Text(
                ' / ${_fmt(controller.value.duration)}',
                style: const TextStyle(fontSize: 11.5, color: Colors.white38),
              ),
              const Spacer(),
              _MuteButton(controller: controller),
              Text(
                '${controller.value.playbackSpeed.toStringAsFixed(1)}x',
                style: const TextStyle(fontSize: 11.5, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _MuteButton extends StatefulWidget {
  const _MuteButton({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<_MuteButton> {
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _muted = !_muted);
        widget.controller.setVolume(_muted ? 0 : 1);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Icon(
          _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          size: 17,
          color: _muted ? Colors.white54 : Colors.white70,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.episode,
    required this.onBack,
  });

  final String title;
  final String episode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3000000), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      episode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SniffHint extends StatelessWidget {
  const _SniffHint();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xE6000000), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: Colors.white38,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.capturing,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white54,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_tethering_error_rounded,
              size: 34,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white38,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: Text(
                t.retry,
                style: TextStyle(fontSize: 14, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
