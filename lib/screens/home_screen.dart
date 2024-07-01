import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:kubrick/widgets/home_app_bar.dart';
import 'package:kubrick/widgets/recording_list.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecordingService recordingService = RecordingService();
  //RxList<Recording> recordings = <Recording>[].obs;
  bool isRecording = false;
  var sharedState = Get.find<SharedState>();
  var recordingsController = Get.find<RecordingsController>();
  final Uuid uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      recordingsController.fetchRecordings();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
        Permission.audio
      ].request();

    //await controller.checkPermission();
  }

  Future startRecording() async {
    try {
      await recordingService.startRecording();
      setState(() {
        isRecording = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Future stopRecording() async {
    try {
      Recording? recording = await recordingService.stopRecording();
      if (recording != null) {
        isRecording = false;
        Get.find<RecordingsController>().recordings.add(recording);
      }
    } catch (e) {
      print(e);
    }
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
        appBar: const HomeAppBar(),
        body: Column(
          children: <Widget>[
            Expanded(
              child: GetBuilder<RecordingsController>(
              builder: (recording) => RecordingList(
                recordings: recordingsController.recordings,
                onPlay: (Recording recording) {
                  sharedState.currentPath.value = recording.path.value;
                  sharedState.isLoading.value = true;
                  setState(() {});
                },
                onDelete: (Recording recording) {
                  DatabaseHelper.deleteRecording(recording);
                  recordingsController.recordings.remove(recording);
                  setState(() {});
                },
              )
            )),
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Container(),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: ElevatedButton(
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
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton(
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                                if(result != null) {
                                  File file = File(result.files.single.path!);
                                  Directory dir = await getApplicationDocumentsDirectory();
                                  final path = dir.path;
                                  final String ext = p.extension(file.path);
                                  final newFile = await file.copy('$path/${uuid.v1()}$ext');
                                  DateTime now = DateTime.now();
                                  String formattedDate = DateFormat('EEEE \'at\' HH:mm').format(now);
                                  Recording addedRecording = Recording(
                                    path: newFile.path,
                                    createdAt: now,
                                    name: formattedDate
                                  );
                                  await DatabaseHelper.insertRecording(addedRecording);
                                  await recordingService.transcribeRecording(addedRecording);
                                  recordingsController.fetchRecordings();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(10),
                                iconColor: Colors.grey[100],
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 20,
                              )
                            ),
                          ),
                        )
                      ],
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