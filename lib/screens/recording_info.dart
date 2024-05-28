import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kubrick/main.dart';
import 'package:path/path.dart' as p;

class RecordingInfoScreen extends StatefulWidget {
  final Recording recording;
  const RecordingInfoScreen({super.key, required this.recording});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == '1') {
            // Delete logic goes here
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: '1',
            child: Text('Delete'),
          )
        ],
        icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                StreamBuilder(
                  stream: player.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return IconButton(
                      onPressed: () {
                        if (isPlaying) {
                          player.pause();
                        } else {
                          player.play();
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 48,
                      ),
                      color: Colors.blue,
                      splashRadius: 24,
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}