import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MainApp());
}

class Recording {
  final String path;
  final Duration duration;
  final DateTime recordedAt;

  Recording({
    required this.path,
    required this.duration,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'duration': duration.inMilliseconds,
    'recordedAt': recordedAt.toIso8601String(),
  };
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  MainAppState createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  final recorder = FlutterSoundRecorder();
  bool isRecorderReady = false;
  List<Recording> recordings = [];

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
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
  }

  Future record() async {
    if(!isRecorderReady) return;
    await recorder.startRecorder(toFile: 'audio');
  }

  Future stop() async {
    if(!isRecorderReady) return;
    final path = await recorder.stopRecorder();
    final audioFile = File(path!);
    final duration = await audioFile.length();
    final recording = Recording(path: path, duration: Duration(milliseconds: duration), recordedAt: DateTime.now());
    await saveFile(recording);
    recordings.add(recording);
    setState(() {});
  }

  /* void checkRecordings(String path) async {
    final dir = Directory(path);

    if(await dir.exists()){
      final files = dir.listSync();
      final foundRecordings = files.where((file) => file.path.endsWith('.mp3')).toList();
      if(foundRecordings.isEmpty){
        //no recordings
      } else {
        for (var recording in foundRecordings) {
          recordings.add();
        }
        setState(() {});
      }
    }
  } */

  void saveFile(Recording recording) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${recording.path}.json');
    await file.writeAsString(jsonEncode(recording.toJson()));
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
                    subtitle: Text('${recordings[index]}'),
                  );
                },
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(10),
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
                            fontSize: 50,
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
                        padding: const EdgeInsets.all(5),
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