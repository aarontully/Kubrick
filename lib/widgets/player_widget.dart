import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:kubrick/models/recording_class.dart';

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
  List? paragraphs;
  PlayerController controller = PlayerController();
  dynamic waveFormData;
  int currentPosition = 0;

  @override
  void initState() {
    super.initState();

    _initialize();
      controller.onCurrentDurationChanged.listen((event) {
        if (mounted) {
          setState(() {
            currentPosition = event;
          });
        }
      });

      if (widget.recording.transcription != null) {
        paragraphs = (widget.recording.transcription!['data']['transcription']['result']['results']['channels'][0]['alternatives'][0]['paragraphs']['paragraphs'] as List);
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /* void updateCurrentPosition(int position) {
    setState(() {
      currentPosition = position;
    });
  } */

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              IconButton(
                onPressed: () async {
                  if (controller.playerState.isPlaying) {
                    await controller.pausePlayer();
                  } else {
                    await controller.startPlayer(finishMode: FinishMode.loop);
                  }
                  if (mounted) {
                    setState(() {});
                  } // Ensure the UI updates
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
                  waveformData: waveFormData ?? [],
                ),
              )
            ],
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var paragraph in paragraphs!)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var sentence in paragraph['sentences'])
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    final startTime = (sentence['start'] * 1000).toInt();
                                    controller.seekTo(startTime);
                                    controller.startPlayer();
                                  },
                                  child: Text(
                                    sentence['text'],
                                    style: TextStyle(
                                      color: (currentPosition / 1000) >= sentence['start'] && (currentPosition / 1000) <= sentence['end'] ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      )
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}