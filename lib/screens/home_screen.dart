import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/metadata_class.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:kubrick/utils/file_picker_util.dart';
import 'package:kubrick/utils/permission_checker.dart';
import 'package:kubrick/widgets/home_app_bar.dart';
import 'package:kubrick/widgets/recording_list.dart';
import 'package:loading_indicator/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecordingService recordingService = RecordingService();
  var sharedState = Get.find<SharedState>();
  Metadata? metadata;

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
    metadata = await showDialog<Metadata>(
    context: context,
    builder: (BuildContext context) {
      var dialogMetadata = Metadata();
      var formKey = GlobalKey<FormState>();

      return Theme(
        data: ThemeData(
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
        child: SingleChildScrollView(
          child: AlertDialog(
            title: const Text('Enter Recording Details'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Shoot Day'),
                    validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    if(int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                    onSaved: (value) {
                      dialogMetadata.shoot_day = value!.toUpperCase();
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contestant'),
                    validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                    onSaved: (value) {
                      dialogMetadata.contestant = value!.toUpperCase();
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Camera'),
                    validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                    onSaved: (value) {
                      dialogMetadata.camera = value!.toUpperCase();
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Audio'),
                    validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                    onSaved: (value) {
                      dialogMetadata.audio = value!.toUpperCase();
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Producer'),
                    validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                    onSaved: (value) {
                      dialogMetadata.producer = value!.toUpperCase();
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      var now = DateTime.now();

                      if (formKey.currentState?.validate() ?? false) {
                        formKey.currentState?.save();
                        dialogMetadata.timecode = now;
                        Navigator.of(context).pop(dialogMetadata);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green[700],
                    ),
                    child: const Text('Start Record'),
                  ),
                ]
              )
            ],
          ),
        )
      );
    },
  );

    if (metadata != null) {
      try {
        await recordingService.startRecording(metadata!);
        sharedState.setRecording(true);
      } catch (e) {
        print(e);
      }
    }
  }

  Future stopRecording() async {
    try {
      sharedState.setRecording(false);
      setState(() {});
      await recordingService.stopRecording(metadata!);
    } catch (e) {
      print(e);
      if(e is FormatException) {
        print('Server connection failed, but the recording was saved locally.');
      }
    }

    Get.find<RecordingsController>().fetchRecordings();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecordingsController>(
      init: RecordingsController(),
      builder: (recordingsController) => MaterialApp(
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
                )
              ),
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
                                  sharedState.isRecording.value ? Icons.stop : Icons.mic_rounded,
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
                                  await FilePickerUtil.pickAndSaveFile();
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
      ),
    );
  }
}