import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/content_item_model.dart';
import '../controllers/playlist_controller.dart';

class VideoPlayerWidget extends ConsumerStatefulWidget {
  final VideoItemModel item;

  const VideoPlayerWidget({super.key, required this.item});

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _completed = false;

  // Yükleme/oynatma için maksimum bekleme süresi — sonra bir sonraki içeriğe geç
  static const _initTimeout = Duration(seconds: 30);
  static const _maxPlayDuration = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final cache = ref.read(cacheServiceProvider);

    // Arka planda indir (non-blocking)
    cache.downloadVideo(widget.item.id, widget.item.downloadUrl);

    // Önce local cache'e bak
    final localFile = await cache.getCachedVideo(widget.item.id);

    VideoPlayerController ctrl;
    if (localFile != null) {
      debugPrint('[Video] Local cache\'ten oynatılıyor: ${widget.item.id}');
      ctrl = VideoPlayerController.file(localFile);
    } else {
      debugPrint('[Video] Network URL\'den oynatılıyor: ${widget.item.downloadUrl}');
      ctrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.item.downloadUrl));
    }

    try {
      // 30 saniyede initialize olmasa bir sonraki içeriğe geç
      await ctrl.initialize().timeout(_initTimeout);
    } catch (e) {
      debugPrint('[Video] Initialize hatası/timeout: $e');
      ctrl.dispose();
      if (mounted) _goNext();
      return;
    }

    ctrl.addListener(_onPlayerUpdate);
    ctrl.setLooping(false);

    if (mounted) {
      setState(() {
        _controller = ctrl;
        _initialized = true;
      });
      ctrl.play();
      debugPrint('[Video] Oynatma başladı, süre: ${ctrl.value.duration}');

      // Güvenlik zamanlayıcısı: video süresinden 5 sn sonra geç
      // (onPlayerUpdate tetiklenmediği durumlar için)
      final safeDuration = ctrl.value.duration > Duration.zero
          ? ctrl.value.duration + const Duration(seconds: 5)
          : _maxPlayDuration;
      Future.delayed(safeDuration, () {
        if (mounted && !_completed) {
          debugPrint('[Video] Güvenlik zamanlayıcısı tetiklendi');
          _goNext();
        }
      });
    } else {
      ctrl.dispose();
    }
  }

  void _onPlayerUpdate() {
    final ctrl = _controller;
    if (ctrl == null || _completed) return;
    if (ctrl.value.position >= ctrl.value.duration &&
        ctrl.value.duration > Duration.zero &&
        !ctrl.value.isPlaying) {
      debugPrint('[Video] Tamamlandı, sonraki içeriğe geçiliyor');
      _goNext();
    }
  }

  void _goNext() {
    if (_completed) return;
    _completed = true;
    ref.read(playlistControllerProvider.notifier).onVideoCompleted();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white24));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    super.dispose();
  }
}
