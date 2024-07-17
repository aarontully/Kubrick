import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/widgets/player_widget.dart';

class InfoTabController extends StatefulWidget {
  final String createdAt;
  final String duration;
  final String summary;
  final String transcription;
  final Recording recording;

  InfoTabController({required this.createdAt, required this.duration, required this.summary, required this.transcription, required this.recording});

  @override
  _InfoTabControllerState createState() => _InfoTabControllerState();
}

class _InfoTabControllerState extends State<InfoTabController> {
  late AudioPlayer player = AudioPlayer();

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
                  subtitle: Text('${widget.duration}'),
                ),
                ListTile(
                  title: const Text('Summary'),
                  subtitle: Text((widget.summary.isEmpty) ? 'No summary' : widget.summary),
                ),
              ],
            ),
            Column(
              children: <Widget>[
                ListTile(
                  title: Text(widget.transcription),
                )
              ],
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