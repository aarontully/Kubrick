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
import 'package:kubrick/screens/recording_info.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MainApp());
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
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
        getRecordings().then((result) {
          setState(() {
            recordings = result;
          });
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
      String path = '${directory.path}/${uuid.v1()}.aac';
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

  Future<List<Recording>> getRecordings() async {
    final List<Map<String, dynamic>> maps = await db!.query('recordings');

    return List.generate(maps.length, (index) {
      return Recording(
        path: maps[index]['path'],
        createdAt: DateTime.parse(maps[index]['createdAt']),
      );
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
                    return Dismissible(
                      key: Key(recordings![index].path!),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete Recording'),
                              content: const Text('Are you sure you want to delete this recording?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        var pathToDelete = recordings![index].path;
                        setState(() {
                          recordings!.removeAt(index);
                        });
                        await db!.delete('recordings', where: 'path = ?', whereArgs: [pathToDelete]);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                      child: ListTile(
                        title: Text(fileName),
                        subtitle: Text(formattedDate),
                        onTap: () async {
                          if(recordings != null && recordings!.isNotEmpty && index >= 0 && index < recordings!.length) {
                            Navigator.push(
                            context,
                              MaterialPageRoute(builder: (context) => RecordingInfoScreen(
                                recording: recordings![index],
                                db: db!,
                                onDelete: (recording) async {
                                  int index = recordings!.indexWhere((element) => element == recording);
                                  if(index != -1) {
                                    recordings!.removeAt(index);
                                  }
                                  recordings = await getRecordings();
                                  setState(() {});
                                },
                              ))
                            );
                          }
                        },
                      ),
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