import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MandirLivePlayerScreen extends StatefulWidget {
  final String mandirName;
  final String liveUrl;

  const MandirLivePlayerScreen({
    super.key,
    required this.mandirName,
    required this.liveUrl,
  });

  @override
  State<MandirLivePlayerScreen> createState() => _MandirLivePlayerScreenState();
}

class _MandirLivePlayerScreenState extends State<MandirLivePlayerScreen> {
  YoutubePlayerController? _controller;
  bool _invalidUrl = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.liveUrl);
    if (videoId == null) {
      _invalidUrl = true;
    } else {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          isLive: true, // live badge + progress bar hata deta hai player me
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_invalidUrl || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mandirName)),
        body: const Center(child: Text("Live darshan link uplabdh nahi hai")),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: false,
        progressIndicatorColor: Colors.red,
        liveUIColor: Colors.red,
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.mandirName)),
          body: Column(
            children: [
              player,
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "LIVE",
                        style: TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.mandirName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
