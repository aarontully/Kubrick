import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/widgets/info_tab_controller.dart';
import 'package:loading_indicator/loading_indicator.dart';


class RecordingInfoScreen extends StatefulWidget {
  final Recording recording;
  const RecordingInfoScreen({super.key, required this.recording});

  @override
  _RecordingInfoScreenState createState() => _RecordingInfoScreenState();
}

class _RecordingInfoScreenState extends State<RecordingInfoScreen> {
  final sharedState = Get.find<SharedState>();

  String formatDuration(double durationInSeconds) {
    int mins = (durationInSeconds / 60).floor();
    double seconds = durationInSeconds % 60;
    return '$mins:${seconds.toStringAsFixed(0).padLeft(2, '0')}';
  }

  String formatDate(String dateInString) {
    if(dateInString == 'No date') return dateInString;
    DateTime date = DateTime.parse(dateInString);
    String formattedDate = DateFormat('dd MMMM yyyy').format(date);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: sharedState.isLoading.value && widget.recording.path.value == sharedState.currentPath.value
      ? const Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: LoadingIndicator(
            indicatorType: Indicator.ballClipRotateMultiple,
            colors: [Color(0xFFE4E4E4)],
          ),
        ),
      )
      : InfoTabController(
        createdAt: formatDate(widget.recording.transcription?['data']['transcription']['completed_at'] ?? 'No date'),
        duration: formatDuration(widget.recording.transcription?['data']['transcription']['result']['metadata']['duration'] ?? 0.0),
        summary: widget.recording.transcription?['data']['transcription']['result']['results']['summary']['short'] ?? 'No summary',
        transcription: widget.recording.transcription?['data']['transcription']['result']['results']['channels'][0]['alternatives'][0]['paragraphs']['paragraphs'] ?? [],
        recording: widget.recording,
      )
    );
  }
}