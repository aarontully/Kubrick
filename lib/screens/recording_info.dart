import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kubrick/main.dart';
import 'package:kubrick/services/ai_api_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

class RecordingInfoScreen extends StatefulWidget {
  final Recording recording;
  final Database? db;
  final Function onDelete;
  const RecordingInfoScreen({super.key, required this.recording, this.db, required this.onDelete});

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

  Future<void> deleteRecording() async {
    File file = File(widget.recording.path!);
    if (await file.exists()) {
      await file.delete();
    }

    await widget.db!.delete(
      'recordings',
      where: 'path = ?',
      whereArgs: [widget.recording.path],
    );
    widget.onDelete(widget.recording);
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
    setState(() {});
  }

  Future<void> transcribeAudio() async {
    final apiService = ApiService(baseUrl: 'https://transcription.staging.endemolshine.com.au/api/v1');
    final response = await apiService.get('user');

    if (response.statusCode == 200) {
      //final transcription = response.body;
      // Use the 'transcription' variable here
    } else {
      //print('Didnt work');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == '1') {
            transcribeAudio();
          }
          else if (value == '2') {
            deleteRecording();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: '1',
            child: Text('Transcribe'),
          ),
          const PopupMenuItem(
            value: '2',
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