import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MainApp());
}

class Recording {
  final String path;
  final Duration duration;
  final String recordedAt;

  Recording({
    required this.path,
    required this.duration,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'duration': duration.inMilliseconds,
    'recordedAt': recordedAt,
  };
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  MainAppState createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  final recorder = FlutterSoundRecorder();
  final player = FlutterSoundPlayer();
  bool isRecorderReady = false;
  List<Recording> recordings = [];
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    initRecorder();
    initPlayer();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    player.closePlayer();
    super.dispose();
  }

  Future initRecorder() async {
    final status = await Permission.microphone.request();

    if(status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }

    isRecorderReady = true;
    await recorder.openRecorder();
    recorder.setSubscriptionDuration(
      const Duration(milliseconds: 500)
    );

    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory('${directory.path}/audio/');
    if(dir.existsSync()){
      dir.listSync().forEach((file) {
        if(file.path.endsWith('.json')) {
          final recordingJson = File(file.path).readAsStringSync();
          final recordingMap = jsonDecode(recordingJson);
          final recording = Recording(path: recordingMap['path'], duration: Duration(milliseconds: recordingMap['duration']), recordedAt: recordingMap['recordedAt']);
          recordings.add(recording);
        }
      });
    }
    setState(() {});
  }

  Future initPlayer() async {
    await player.openPlayer();
  }

  Future record() async {
    if(!isRecorderReady) return;
    await recorder.startRecorder(toFile: 'audio');
  }

  Future stop() async {
    if(!isRecorderReady) return;
    await recorder.stopRecorder();
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(now);
    final createUuid = uuid.v1();
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory('${directory.path}/audio/');
    if(!dir.existsSync()){
      dir.createSync(recursive: true);
    }
    final file = File('${dir.path}/$createUuid.json');
    final recording = Recording(path: createUuid, duration: const Duration(milliseconds: 0), recordedAt: formattedDate);
    await file.writeAsString(jsonEncode(recording.toJson()));
    recordings.add(recording);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kubrick Transcriber'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: recordings.length,
                itemBuilder: (context, index){
                  return ListTile(
                    title: Text(recordings[index].path),
                    subtitle: Text(recordings[index].recordedAt),
                    onTap: () async {
                      final directory = await getApplicationDocumentsDirectory();
                      final path = '${directory.path}/audio/${recordings[index].path}.json';
                      if(await File(path).exists()){
                        await player.startPlayer(fromURI: path);
                      } else {
                        print('File does not exist');
                      }
                    },
                  );
                },
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    StreamBuilder<RecordingDisposition>(
                      stream: recorder.onProgress,
                      builder: (context, snapshot) {
                        final duration = snapshot.hasData ? snapshot.data!.duration : Duration.zero;
                        String twoDigits(int n) => n.toString().padLeft(2, '0');
                        final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
                        final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
                        return Text(
                          '$twoDigitMinutes:$twoDigitSeconds',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if(recorder.isRecording){
                          await stop();
                        } else {
                          await record();
                        }
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                        backgroundColor: Colors.red[600],
                        iconColor: Colors.red[900],
                      ),
                      child: Icon(
                        recorder.isRecording ? Icons.stop : Icons.mic_rounded,
                        size: 60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}