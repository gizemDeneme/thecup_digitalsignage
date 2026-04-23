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

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final cache = ref.read(cacheServiceProvider);

    // Download for future use (non-blocking)
    cache.downloadVideo(widget.item.id, widget.item.downloadUrl);

    // Try local cache first
    final localFile = await cache.getCachedVideo(widget.item.id);

    VideoPlayerController ctrl;
    if (localFile != null) {
      ctrl = VideoPlayerController.file(localFile);
    } else {
      ctrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.item.downloadUrl));
    }

    await ctrl.initialize();
    ctrl.addListener(_onPlayerUpdate);
    ctrl.setLooping(false);

    if (mounted) {
      setState(() {
        _controller = ctrl;
        _initialized = true;
      });
      ctrl.play();
    } else {
      ctrl.dispose();
    }
  }

  void _onPlayerUpdate() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (ctrl.value.position >= ctrl.value.duration &&
        ctrl.value.duration > Duration.zero &&
        !ctrl.value.isPlaying) {
      ref.read(playlistControllerProvider.notifier).onVideoCompleted();
    }
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
