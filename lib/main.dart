import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/ai_api_service.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/screens/recording_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

void main() {
  HttpOverrides.global = MyHttpOverrides();

  Get.put(SharedState());
  runApp(const MainApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
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
  bool isRecording = false;
  final player = AudioPlayer();
  var sharedState = Get.find<SharedState>();

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      getRecordings().then((result) {
        setState(() {
          recordings = result;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> requestPermissions() async {
    PermissionStatus micStatus = await Permission.microphone.status;
    PermissionStatus storageStatus = await Permission.storage.status;

    //await controller.checkPermission();

    if (micStatus.isDenied || storageStatus.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();

      if (!(statuses[Permission.microphone]!.isGranted &&
          statuses[Permission.storage]!.isGranted)) {
        //didnt get all the permissions - handle this
        return;
      }
    }
  }

  Future<void> startRecording() async {
    if (await record.hasPermission()) {
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
    sharedState.setLoading(true);
    sharedState.setCurrentPath(path!);
    setState(() {
      isRecording = false;
    });

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE \'at\' HH:mm').format(now);

    Recording recording = Recording(
      path: path,
      createdAt: now,
      name: formattedDate,
    );

    await DatabaseHelper.insertRecording(recording);

    setState(() {
      recordings?.add(recording);
    });

    //transcribe section
    final apiService = ApiService();
    final fileBytes = await File(recording.path!).readAsBytes();
    // TODO: large uploads will put it into ram and crash the app
    const chunkSize = 1024 * 1024; //1MB
    final chunkCount = (fileBytes.length / chunkSize).ceil();
    final fileName = p.basename(recording.path!);

    final uploadId =
        await apiService.initUpload(chunkCount, fileName, fileBytes.length);

    for (var i = 0; i < chunkCount; i++) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, fileBytes.length);
      final chunkBytes = fileBytes.sublist(start, end);

      await apiService.uploadChunk(uploadId, i, chunkBytes.length, chunkBytes);
    }

    await apiService.completeUpload(uploadId);

    //start transcription

    //Data data = await apiService.fetchTranscription(uploadId, chunkCount, chunkSize, fileName);
    //print(data.file.name);
    sharedState.setLoading(false);
  }

  Future<List<Recording>> getRecordings() async {
    return DatabaseHelper.getRecordings();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        textTheme: TextTheme(
          displayLarge:
              const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.oswald(
            fontSize: 30,
            fontStyle: FontStyle.italic,
          ),
          bodyMedium: GoogleFonts.merriweather(),
          displaySmall: GoogleFonts.pacifico(),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kubrick Transcriber'),
          actions: [
            IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Add filter logic here
                })
          ],
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
                          //String fileName = p.basename(recordings![index].path!);
                          String name = recordings![index].name!;
                          String formattedDate = DateFormat('yyyy-MM-dd')
                              .format(recordings![index].createdAt);
                          return Dismissible(
                            key: Key(recordings![index].path!),
                            direction: DismissDirection.horizontal,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                return await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete Recording'),
                                      content: const Text(
                                          'Are you sure you want to delete this recording?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                final TextEditingController controller = TextEditingController();
                                return await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Rename Recording'),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter new name',
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                            DatabaseHelper.updateRecording(recordings![index]);
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            onDismissed: (direction) async {
                              var pathToDelete = recordings![index].path;
                              var nameToDelete = recordings![index].name;
                              setState(() {
                                recordings!.removeAt(index);
                              });
                              await DatabaseHelper.deleteRecording(Recording(
                                  path: pathToDelete,
                                  createdAt: DateTime.now(),
                                  name: nameToDelete));
                            },
                            background: Container(
                              color: Colors.orange,
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                padding: EdgeInsets.all(20),
                                child: Icon(Icons.edit, color: Colors.white),
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              child: const Padding(
                                padding: EdgeInsets.all(20),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                            ),
                            child: ListTile(
                              title: Text(name),
                              subtitle: Text(formattedDate),
                              trailing: sharedState.currentPath.value ==
                                          recordings![index].path &&
                                      sharedState.isLoading.value == true
                                  ? const LoadingIndicator(
                                      indicatorType:
                                          Indicator.ballClipRotateMultiple,
                                      colors: [Color(0xFFE4E4E4)],
                                    )
                                  : null,
                              onTap: () async {
                                if (recordings != null &&
                                    recordings!.isNotEmpty &&
                                    index >= 0 &&
                                    index < recordings!.length) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              RecordingInfoScreen(
                                                  recording: recordings![index],
                                                  onDelete: (recording) async {
                                                    int index = recordings!
                                                        .indexWhere((element) =>
                                                            element ==
                                                            recording);
                                                    if (index != -1) {
                                                      recordings!
                                                          .removeAt(index);
                                                    }
                                                    recordings =
                                                        await DatabaseHelper
                                                            .getRecordings();
                                                    setState(() {});
                                                  },
                                                  onSubmitted: (value) async {
                                                    await getRecordings();
                                                    setState(() {});
                                                  })));
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
                    if (isRecording)
                      Container(
                        height: 50,
                        width: 150,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: const LoadingIndicator(
                          indicatorType: Indicator.lineScalePulseOutRapid,
                          colors: [Color(0xFFE4E4E4)],
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: () async {
                        if (isRecording) {
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
