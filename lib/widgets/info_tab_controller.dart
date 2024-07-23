import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/file_api_service.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:kubrick/widgets/conversation_tab.dart';
import 'package:kubrick/widgets/player_widget.dart';

class InfoTabController extends StatefulWidget {
  final String createdAt;
  final String duration;
  final String summary;
  final List<dynamic> transcription;
  final Recording recording;

  const InfoTabController({
    super.key,
    required this.createdAt,
    required this.duration,
    required this.summary,
    required this.transcription,
    required this.recording
  });

  @override
  _InfoTabControllerState createState() => _InfoTabControllerState();
}

class _InfoTabControllerState extends State<InfoTabController> {
  late AudioPlayer player = AudioPlayer();
  final FileApiService fileApiService = FileApiService();

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      player.setSource(DeviceFileSource(widget.recording.path.value));
    });
  }

  @override
  void dispose() {
    player.dispose();
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              itemBuilder: (context) {
                List<PopupMenuEntry<String>> menuItems = <PopupMenuEntry<String>> [
                  const PopupMenuItem(
                    value: 'download',
                    child: Text('Download'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  )
                ];

                if(widget.recording.status.value != 'Uploaded') {
                  menuItems.insert(1, const PopupMenuItem(
                    value: 'reprocess',
                    child: Text('Re-Process'),
                  ));
                  menuItems.removeAt(1);
                }

                return menuItems;
              },
              onSelected: (value) async {
                if (value == 'download') {
                  fileApiService.downloadFile(widget.recording.uploadId!);
                }
                if (value == 'reprocess') {
                  try {
                    RecordingService recordingService = RecordingService();
                    final response = await recordingService.transcribeRecording(widget.recording);
                    if(response) {
                      widget.recording.status.value = 'Uploaded';
                      await DatabaseHelper.updateRecording(widget.recording);
                    }
                  } catch (e) {
                    print('Failed to reprocess recording: $e');
                  }
                }
                if (value == 'delete') {
                  try {
                    DatabaseHelper.deleteRecording(widget.recording);
                  } catch (e) {
                    print('Failed to delete local recording: $e');
                  }
                  try {
                    fileApiService.deleteFile(widget.recording.uploadId!);
                  } catch (e) {
                    print('Failed to delete remote recording: $e');
                  }
                }
              },
            )
          ],
        ),
        body: TabBarView(
          children: [
            Column(
              children: <Widget>[
                ListTile(
                  title: const Text('Created At'),
                  subtitle: Text(widget.createdAt),
                ),
                ListTile(
                  title: const Text('Duration'),
                  subtitle: Text(widget.duration),
                ),
                ListTile(
                  title: const Text('Summary'),
                  subtitle: Text((widget.summary.isEmpty) ? 'No summary' : widget.summary),
                ),
              ],
            ),
            SingleChildScrollView(
              child: Column(
              children: <Widget>[
                ConversationTab(transcription: widget.transcription)
              ],
            ),
            ),
            Center(
              child: Column(
                children: <Widget>[
                  PlayerWidget(player: player),
                ],
              ),
            ),
          ]
        )
      ),
    );
  }
}