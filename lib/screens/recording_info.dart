import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/models/transcription_class.dart';
import 'package:kubrick/services/ai_api_service.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';


class RecordingInfoScreen extends StatefulWidget {
  final Recording recording;
  final Function onDelete;
  const RecordingInfoScreen({super.key, required this.recording, required this.onDelete});

  @override
  _RecordingInfoScreenState createState() => _RecordingInfoScreenState();
}

class _RecordingInfoScreenState extends State<RecordingInfoScreen> {
  late AudioPlayer player;
  late Stream<Duration> positionStream;

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

  Future<void> transcribeAudio() async {
    final apiService = ApiService();
    final fileBytes = await File(widget.recording.path!).readAsBytes();
    //large uploads will put it into ram and crash the app
    const chunkSize = 1024 * 1024; //1MB
    final chunkCount = (fileBytes.length / chunkSize).ceil();
    final fileName = p.basename(widget.recording.path!);

    final uploadId = await apiService.initUpload(chunkCount, fileName, fileBytes.length);

    for (var i = 0; i < chunkCount; i++) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, fileBytes.length);
      final chunkBytes = fileBytes.sublist(start, end);

      await apiService.uploadChunk(uploadId, i, chunkBytes.length, chunkBytes);
    }

    await apiService.completeUpload(uploadId);

    //start transcription
    Data data = await apiService.fetchTranscription(uploadId, chunkCount, chunkSize, fileName);
    print(data.file.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: ElevatedButton(
              style: ButtonStyle(
                padding: WidgetStateProperty.all<EdgeInsets>(
                  const EdgeInsets.all(20.0)
                )
              ),
              onPressed: () {
                transcribeAudio();
              },
              child: const Text(
                'Transcribe',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
            Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(p.basename(widget.recording.path!)),
                  Text(DateFormat('yyyy-MM-dd HH:mm').format(widget.recording.createdAt)),
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