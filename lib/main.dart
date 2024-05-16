import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';


void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  MainAppState createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  final recorder = FlutterSoundRecorder();

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
    var status = await Permission.microphone.request();

    if(status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }

    await recorder.openRecorder();
  }

  Future record() async {
    await recorder.startRecorder(toFile: 'audio');
  }

  Future stop() async {
    await recorder.stopRecorder();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kubrick Transcriber'),
        ),
        body: Center(
        child: ElevatedButton(
          onPressed: () async {
            if(recorder.isRecording) {
              await stop();
            } else {
              await record();
            }

            setState(() {});
          },
          child: Icon(
            recorder.isRecording ? Icons.stop : Icons.mic,
            size: 80,
          ),
        ),
      ),
      ),
    );
  }
}
