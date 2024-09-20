import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/models/sentence_class.dart';

class PlayerWidget extends StatefulWidget {
  final String path;
  final Recording recording;

  const PlayerWidget({
    required this.path,
    required this.recording,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerController controller = PlayerController();
  dynamic waveFormData;
  int currentPosition = 0;
  List<Sentence> sentences = [];

  @override
  void initState() {
    super.initState();
      _initialize();
      controller.onCurrentDurationChanged.listen((event) {
        setState(() {
          currentPosition = event;
        });
      });
    if(widget.recording.transcription != null) {
        sentences = (widget.recording.transcription!['data']['transcription']['result']['results']['channels'][0]['alternatives'][0]['paragraphs']['paragraphs'][0]['sentences'] as List)
        .map((sentence) => Sentence.fromMap(sentence))
        .toList();
      }
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

    if (mounted) {
      setState(() {
        waveFormData = waveFormData;
      });
    }
  }

  void updateIcon() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (waveFormData != null)
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            if(!controller.playerState.isStopped)
              IconButton(
                onPressed: () async {
                  if (controller.playerState.isPlaying) {
                    await controller.pausePlayer();
                  } else {
                    await controller.startPlayer(finishMode: FinishMode.loop);
                  }
                  updateIcon();
                },
                icon: Icon(controller.playerState.isPlaying ? Icons.stop : Icons.play_arrow),
                color: Colors.white,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            Expanded(
              child: AudioFileWaveforms(
                size: Size(MediaQuery.of(context).size.width, 100),
                playerController: controller,
                enableSeekGesture: true,
                waveformType: WaveformType.long,
                playerWaveStyle: const PlayerWaveStyle(
                  fixedWaveColor: Colors.white54,
                  liveWaveColor: Colors.blue,
                  spacing: 4.0,
                ),
                waveformData: waveFormData,
              ),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: sentences.length,
          itemBuilder: (context, index) {
            final sentence = sentences[index];
            final isActive = (currentPosition / 1000) >= sentence.startTime && (currentPosition / 1000) <= sentence.endTime;
            return Text(
              sentence.text,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey,
              ),
            );
          },
        )
      ],
    );
  }
}