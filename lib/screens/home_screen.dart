import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:kubrick/widgets/home_app_bar.dart';
import 'package:kubrick/widgets/recording_list.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecordingService recordingService = RecordingService();
  RxList<Recording> recordings = <Recording>[].obs;
  bool isRecording = false;
  var sharedState = Get.find<SharedState>();
  var recordingsController = Get.find<RecordingsController>();

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