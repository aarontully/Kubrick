import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/metadata_class.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:kubrick/utils/file_picker_util.dart';
import 'package:kubrick/utils/permission_checker.dart';
import 'package:kubrick/widgets/home_app_bar.dart';
import 'package:kubrick/widgets/metadata_dialog.dart';
import 'package:kubrick/widgets/recording_list.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecordingService recordingService = RecordingService();
  var sharedState = Get.find<SharedState>();
  Metadata? metadata;
  final RecorderController controller = RecorderController();

  @override
  void initState() {
    super.initState();
    sharedState.checkConnectivity();
    PermissionChecker.requestPermissions().then((_) {
      Get.find<RecordingsController>().fetchRecordings();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future startRecording() async {
    if (!await controller.checkPermission()){
      return;
    }
    metadata = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return buildMetadataDialog(context);
      },
    );

    if (metadata != null) {
      try {
        String hours = metadata!.timecode.hour.toString().padLeft(2, '0');
        String minutes = metadata!.timecode.minute.toString().padLeft(2, '0');
        Directory directory = await getApplicationDocumentsDirectory();
        String path = '${directory.path}/${metadata!.shoot_day}_${metadata!.interview_day}_${metadata!.contestant}_${metadata!.camera}_${metadata!.audio}_${hours}_${minutes}_${metadata!.producer}.m4a';
        await controller.record(path: path);
        sharedState.setRecording(true);
      } catch (e) {
        print(e);
      }
    }
  }

  Future stopRecording() async {
    controller.reset();
    try {
      sharedState.setRecording(false);
      setState(() {});
      final path = await controller.stop();
      await recordingService.stopRecording(metadata!, path);
    } catch (e) {
      print(e);
      if (e is FormatException) {
        print('Server connection failed, but the recording was saved locally.');
      }
    }

    Get.find<RecordingsController>().fetchRecordings();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecordingsController>(
      init: RecordingsController(),
      builder: (recordingsController) => Scaffold(
        appBar: const HomeAppBar(),
        body: Column(
          children: <Widget>[
            Expanded(
                child: RecordingList(
              recordings: recordingsController.recordings,
              onPlay: (Recording recording) {
                print(recording.transcription);
              },
              onDelete: (Recording recording) {
                DatabaseHelper.deleteRecording(recording);
                recordingsController.recordings.remove(recording);
                setState(() {});
              },
            )),
            Center(
              child: Container(
                margin: const EdgeInsets.all(40),
                child: Column(
                  children: <Widget>[
                    if (sharedState.isRecording.value == true)
                      Container(
                          height: 50,
                          width: 150,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: AudioWaveforms(
                            enableGesture: false,
                            size: Size(
                              MediaQuery.of(context).size.width / 2, 50,
                            ),
                            recorderController: controller,
                            waveStyle: const WaveStyle(
                              waveColor: Colors.blue,
                            ),
                          ),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Visibility(
                            visible: sharedState.isRecording.value,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await recordingService.restartRecording(metadata!);
                                  final snackbar = SnackBar(
                                    elevation: 0,
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.transparent,
                                    content: AwesomeSnackbarContent(title: 'Restarted', message: 'The recording has now restarted', contentType: ContentType.success),
                                  );
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(snackbar);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(10),
                                  iconColor: const Color.fromARGB(255, 18, 116, 18),
                                ),
                                child: const Icon(
                                  Icons.restart_alt_outlined,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (sharedState.isRecording.value == true) {
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
                                sharedState.isRecording.value
                                    ? Icons.stop
                                    : Icons.mic_rounded,
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
                                  await FilePickerUtil.pickAndSaveFile(context);
                                  recordingsController.fetchRecordings();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(10),
                                  iconColor: Colors.grey[100],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 20,
                                )),
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
