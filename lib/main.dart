import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';

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
  final record = AudioRecorder();
  final uuid = Uuid();
  Database? db;
  bool isRecording = false;
  final player = AudioPlayer();

  Future<List<Recording>> getRecordings() async {
    final List<Map<String, dynamic>> maps = await db!.query('recordings');
    return List.generate(maps.length, (i){
      return Recording.fromMap(maps[i]);
    });
  }

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  @override
  void dispose() {
    db?.close();
    super.dispose();
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

  Future<Recording> stopRecording() async {
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

    return recording;
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
              child: FutureBuilder<List<Recording>>(
                future: getRecordings(),
                builder: (BuildContext context, AsyncSnapshot<List<Recording>> snapshot) {
                  if(snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        String fileName = p.basename(snapshot.data![index].path!);
                        String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(snapshot.data![index].createdAt);
                        return ListTile(
                          title: Text(fileName),
                          subtitle: Text(formattedDate),
                          onTap: () async {
                            await player.setFilePath(snapshot.data![index].path!);
                            player.play();
                          },
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
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