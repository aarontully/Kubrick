import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;

  PlayerWidget({
    required this.player,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  String get durationText => _duration?.toString().split('.').first ?? '';
  String get positionText => _position?.toString().split('.').first ?? '';
  AudioPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();
    _playerState = player.state;
    player.getDuration().then(
      (value) => setState(() => _duration = value),
    );

    player.getCurrentPosition().then(
      (value) => setState(() => _position = value),
    );
    initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  void initStreams() {
    _durationSubscription = player.onDurationChanged.listen(
      (d) => setState(() => _duration = d),
    );

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen(
      (event) => setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      }),
    );

    _playerStateChangeSubscription = player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> play() async {
    await player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> pause() async {
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Future<void> stop() async {
    await player.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = const Duration();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              key: const Key('play_button'),
              onPressed: isPlaying ? null : play,
              iconSize: 48.0,
              icon: const Icon(Icons.play_arrow),
            ),
            IconButton(
              key: const Key('pause_button'),
              onPressed: isPlaying ? () => player.pause() : null,
              iconSize: 48.0,
              icon: const Icon(Icons.pause),
            ),
            IconButton(
              key: const Key('stop_button'),
              onPressed: isPlaying || isPaused ? () => player.stop() : null,
              iconSize: 48.0,
              icon: const Icon(Icons.stop),
            ),
          ],
        ),
        Slider(
          onChanged: (value) {
            final duration = _duration;
            if(duration == null) {
              return;
            }
            final position = value * duration.inMilliseconds;
            player.seek(Duration(milliseconds: position.round()));
          },
          value: (_position != null && _duration != null && _position!.inMilliseconds > 0 && _position!.inMilliseconds < _duration!.inMilliseconds)
              ? _position!.inMilliseconds / _duration!.inMilliseconds
              : 0.0,
        ),
        Text(
          _position != null
              ? '$positionText / $durationText'
              : _duration != null
                ? durationText
                : '',
          style: const TextStyle(fontSize: 16.0),
        )
      ],
    );
  }
}