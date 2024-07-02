import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/screens/recording_info.dart';
import 'package:loading_indicator/loading_indicator.dart';

class RecordingListTile extends StatelessWidget {
  final Recording recording;
  final SharedState sharedState = Get.find<SharedState>();
  final bool isUploaded;

  RecordingListTile({
    super.key,
    required this.recording,
  }) : isUploaded = recording.status.value == 'Uploaded';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(recording.name.value),
      subtitle: Text(DateFormat('yyyy-MM-dd').format(recording.createdAt.value)),
      trailing: sharedState.isProcessing.value == true && sharedState.currentRecording.value == recording ?
      const LoadingIndicator(
        indicatorType: Indicator.ballClipRotateMultiple,
        colors: [Color(0xFFE4E4E4)],
      ) : isUploaded
        ? const Icon(Icons.cloud_done) : const Icon(Icons.cloud_off),
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordingInfoScreen(
              recording: recording,
            ),
          ),
        );
      }
    );
  }
}
