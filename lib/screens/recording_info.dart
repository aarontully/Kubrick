import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/main.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/widgets/editable_text_widget.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

class RecordingInfoScreen extends StatefulWidget {
  final Recording recording;
  final Function onDelete;
  final Function(String) onSubmitted;
  const RecordingInfoScreen({super.key, required this.recording, required this.onDelete, required this.onSubmitted});

  @override
  _RecordingInfoScreenState createState() => _RecordingInfoScreenState();
}

class _RecordingInfoScreenState extends State<RecordingInfoScreen> {
  late AudioPlayer player;
  late Stream<Duration> positionStream;
  final sharedState = Get.find<SharedState>();

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player.setFilePath(widget.recording.path!);
    positionStream = player.positionStream;
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
            Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (sharedState.isLoading.value && widget.recording.path == sharedState.currentPath.value) ...[
                    const Spacer(),
                    const SizedBox(
                      width: 300,
                      height: 300,
                      child: LoadingIndicator(
                        indicatorType: Indicator.ballClipRotateMultiple,
                        colors: [Color(0xFFE4E4E4)],
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    Container(
                      child: const Text('This is the top'),
                    ),
                    const Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            Text('This is the bottom'),
                          ]
                        )
                      ),
                    )
                  ],
                  Text(widget.recording.name!),
                  EditableTextWidget(
                    initialText: widget.recording.name!,
                    onSubmitted: (value) {
                      setState(() {
                        widget.recording.name = value;
                        DatabaseHelper.updateRecording(widget.recording);
                        widget.onSubmitted(value);
                      });
                    },
                  ),
                  StreamBuilder(
                    stream: positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = player.duration ?? Duration.zero;
                      return Slider(
                      onChanged: (value) {
                        player.seek(Duration(seconds: value.toInt()));
                      },
                      value: position.inSeconds.toDouble(),
                      min: 0.0,
                      max: duration.inSeconds.toDouble(),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        StreamBuilder(
                          stream: Rx.combineLatest2<bool, ProcessingState, Tuple2<bool, ProcessingState>>(
                            player.playingStream,
                            player.processingStateStream,
                            (playing, processingState) => Tuple2(playing, processingState),
                          ),
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            final isPlaying = data?.item1 ?? false;
                            final processingState = data?.item2 ?? ProcessingState.idle;
                            final isCompleted = processingState == ProcessingState.completed;
                            return IconButton(
                              onPressed: () {
                                if(!isCompleted){
                                  if (isPlaying) {
                                    player.pause();
                                  } else {
                                    player.play();
                                  }
                                } else {
                                  player.seek(Duration.zero);
                                  player.play();
                                }
                              },
                              icon: Icon(
                                isPlaying && !isCompleted ? Icons.pause : Icons.play_arrow,
                                size: 48,
                              ),
                              color: Colors.blue,
                              splashRadius: 24,
                              );
                            },
                          ),
                        ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}