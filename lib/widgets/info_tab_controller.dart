import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/file_api_service.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:kubrick/services/transcription_api_service.dart';
import 'package:kubrick/widgets/conversation_tab.dart';
import 'package:kubrick/widgets/player_widget.dart';
import 'package:open_file/open_file.dart' as open_file;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class InfoTabController extends StatefulWidget {
  final String createdAt;
  final String duration;
  final String summary;
  final List<dynamic> transcription;
  final Recording recording;

  const InfoTabController(
      {super.key,
      required this.createdAt,
      required this.duration,
      required this.summary,
      required this.transcription,
      required this.recording});

  @override
  _InfoTabControllerState createState() => _InfoTabControllerState();
}

class _InfoTabControllerState extends State<InfoTabController> {
  final FileApiService fileApiService = FileApiService();
  final TranscriptionApiService transcriptionService = TranscriptionApiService();
  SharedState sharedState = Get.find<SharedState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Summary'),
                Tab(text: 'Transcription'),
                Tab(text: 'Player')
              ],
            ),
            title: const Text('Recording Info'),
            actions: [
              Builder(
                builder: (context) => PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> menuItems =
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem(
                        value: 'downloadTranscription',
                        child: Text('Download Transcription'),
                      ),
                      /* const PopupMenuItem(
                        value: 'downloadAudio',
                        child: Text('Download audio'),
                      ), */
                      /* const PopupMenuDivider(), */
                      /* CheckedPopupMenuItem(
                        value: 'sentenceSentiment',
                        checked: sharedState.isSentenceSentiment.value,
                        child: const Text('Sentence Sentiment'),
                      ),
                      CheckedPopupMenuItem(
                        value: 'wordConfidence',
                        checked: sharedState.isWordConfidence.value,
                        child: const Text('Word Confidence'),
                      ), */
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      )
                    ];
                    if (widget.recording.status.value != 'Uploaded') {
                      menuItems.insert(
                          1,
                          const PopupMenuItem(
                            value: 'reprocess',
                            child: Text('Re-Process'),
                          ));
                    }

                    return menuItems;
                  },
                  onSelected: (value) async {
                    if (value == 'downloadAudio') {
                      //fileApiService.downloadFile(widget.recording.uploadId!);
                    }
                    if (value == 'downloadTranscription') {
                      final transcription =
                          await transcriptionService.downloadTranscription(
                              widget.recording.uploadId!,
                              widget.recording.transcriptionId!);
                      final dir = await getApplicationDocumentsDirectory();
                      final date = DateTime.now();
                      final formattedDate =
                          DateFormat('yyyy-MM-dd').format(date);
                      final file = File(join(
                          '${dir.path}/${widget.recording.transcriptionId}_$formattedDate.txt'));
                      await file.writeAsString(transcription);

                      final snackbar = SnackBar(
                        content: const Text('Transcription downloaded'),
                        action: SnackBarAction(
                          label: 'Open',
                          onPressed: () async {
                            if (await file.exists()) {
                              await open_file.OpenFile.open(file.path);
                            }
                          },
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackbar);
                    }
                    if (value == 'reprocess') {
                      try {
                        sharedState.setProcessing(true);
                        RecordingService recordingService = RecordingService();
                        final response = await recordingService
                            .transcribeRecording(widget.recording);
                        if (response) {
                          widget.recording.status.value = 'Uploaded';
                          await DatabaseHelper.updateRecording(
                              widget.recording);
                        }
                        sharedState.setProcessing(false);
                      } catch (e) {
                        print('Failed to reprocess recording: $e');
                        sharedState.setProcessing(false);
                      }
                    }
                    if (value == 'wordConfidence') {
                      sharedState.setWordConfidence(
                          !sharedState.isWordConfidence.value);
                    }
                    if (value == 'sentenceSentiment') {
                      sharedState.setSentenceSentiment(
                          !sharedState.isSentenceSentiment.value);
                    }
                    if (value == 'delete') {
                      try {
                        DatabaseHelper.deleteRecording(widget.recording);
                        print('Del init from info_tab_controller');
                      } catch (e) {
                        print('Failed to delete local recording: $e');
                      }
                      try {
                        fileApiService.deleteFile(widget.recording.uploadId!);
                      } catch (e) {
                        print('Failed to delete remote recording: $e');
                      }

                      // TODO: this isnt working correctly, after popping the navigation the list does not update
                      // and you can till interact with the old object
                      await Get.find<RecordingsController>().fetchRecordings();
                      Navigator.pop(context);
                    }
                  },
                ),
              )
            ],
          ),
          body: sharedState.isProcessing.value == true
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
            Column(
              children: <Widget>[
                ListTile(
                  title: const Text('Created At'),
                  subtitle: SelectableText(widget.createdAt),
                ),
                ListTile(
                  title: const Text('Duration'),
                  subtitle: SelectableText(widget.duration),
                ),
                ListTile(
                  title: const Text('Status'),
                  subtitle: SelectableText(
                    widget.recording.status.value == 'Uploaded'
                        ? 'Uploaded to the cloud successfully'
                        : sharedState.isProcessing.value == true
                            ? 'Processing...Please wait'
                            : 'Local recording only',
                  ),
                ),
                /* ListTile(
                  title: const Text('Summary'),
                  subtitle: SelectableText(
                      (widget.summary.isEmpty) ? 'No summary' : widget.summary),
                  trailing: IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Color(0xFF424242),
                        size: 20.0,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.summary));
                      }),
                ), */
              ],
            ),
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ConversationTab(transcription: widget.transcription, recording: widget.recording),
                ],
              ),
            ),
            Center(
              child: Column(
                children: <Widget>[
                  PlayerWidget(path: widget.recording.path.value, recording: widget.recording),
                ],
              ),
            ),
          ])),
    );
  }
}
