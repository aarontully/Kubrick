import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class PlayerWidget extends StatefulWidget {
  final String path;

  const PlayerWidget({
    required this.path,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerController controller = PlayerController();
  dynamic waveFormData;
  bool isPlaying = false;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
        waveFormData = await controller.extractWaveformData(
        path: widget.path,
        noOfSamples: 100
      );
    } catch (e) {
      waveFormData = null;
    }

    await controller.preparePlayer(
      path: widget.path,
      shouldExtractWaveform: true,
      noOfSamples: 100,
      volume: 1.0,
    );

    setState(() {
      waveFormData = waveFormData;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> play() async {
    isPlaying = true;
    await controller.startPlayer(finishMode: FinishMode.stop);
  }

  Future<void> pause() async {
    isPaused = true;
    await controller.pausePlayer();
  }

  Future<void> stop() async {
    isPlaying = false;
    isPaused = false;
    await controller.stopPlayer();
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
              onPressed: isPlaying ? () => pause() : null,
              iconSize: 48.0,
              icon: const Icon(Icons.pause),
            ),
            IconButton(
              key: const Key('stop_button'),
              onPressed: isPlaying || isPaused ? () => stop() : null,
              iconSize: 48.0,
              icon: const Icon(Icons.stop),
            ),
          ],
        ),
        if (waveFormData != null)
          AudioFileWaveforms(
            size: Size(MediaQuery.of(context).size.width, 100.0),
            playerController: controller,
            enableSeekGesture: true,
            waveformType: WaveformType.long,
            waveformData: waveFormData,
            playerWaveStyle: const PlayerWaveStyle(
              fixedWaveColor: Colors.white54,
              liveWaveColor: Colors.blue,
              spacing: 6.0,
            ),
          )
      ],
    );
  }
}