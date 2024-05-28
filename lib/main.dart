import 'dart:convert';
import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/screens/recording_info.dart';

void main() {
  runApp(const MainApp());
}

class Recording {
  final String? path;
  final DateTime createdAt;

  Recording({required this.path, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Recording fromMap(Map<String, dynamic> map) {
    return Recording(
      path: map['path'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  MainAppState createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  List<Recording>? recordings;
  final record = AudioRecorder();
  final uuid = const Uuid();
  Database? db;
  bool isRecording = false;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      initDatabase().then((_) {
        getRecordings().then((_) {
          setState(() {});
        });
      });
    });
  }

  @override
  void dispose() {
    db?.close();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    PermissionStatus micStatus = await Permission.microphone.status;
    PermissionStatus storageStatus = await Permission.storage.status;

    if(micStatus.isDenied || storageStatus.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();
      print(statuses[Permission.microphone]);
      print(statuses[Permission.storage]);

      if(!(statuses[Permission.microphone]!.isGranted && statuses[Permission.storage]!.isGranted)) {
        //didnt get all the permissions - handle this
        return;
      }
    }
  }

  Future<void> initDatabase() async {
    db = await openDatabase(
      p.join(await getDatabasesPath(), 'recordings.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE recordings (id INTEGER PRIMARY KEY, path TEXT, createdAt TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> startRecording() async {
    if(await record.hasPermission()) {
      Directory directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}/audio/${uuid.v1()}.aac';
      await record.start(const RecordConfig(), path: path);
      setState(() {
        isRecording = true;
      });
    }
  }

  Future<void> stopRecording() async {
    String? path = await record.stop();
    setState(() {
      isRecording = false;
    });

    Recording recording = Recording(
      path: path,
      createdAt: DateTime.now(),
    );

    await db?.insert(
      'recordings',
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    setState(() {
      recordings?.add(recording);
    });
  }

  Future<void> getRecordings() async {
    final List<Map<String, dynamic>> maps = await db!.query('recordings');
    setState(() {
      recordings = List.generate(maps.length, (i) {
        return Recording.fromMap(maps[i]);
      });
    });
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
              child: Center(
              child: recordings == null
                ? const CircularProgressIndicator()
                : ListView.builder(
                  itemCount: recordings!.length,
                  itemBuilder: (context, index) {
                  String fileName = p.basename(recordings![index].path!);
                  String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(recordings![index].createdAt);
                  return ListTile(
                    title: Text(fileName),
                    subtitle: Text(formattedDate),
                    onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RecordingInfoScreen(recording: recordings![index]))
                    );
                    },
                  );
                  },
                ),
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        if(isRecording){
                          await stopRecording();
                        } else {
                          await startRecording();
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
                        isRecording ? Icons.stop : Icons.mic_rounded,
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