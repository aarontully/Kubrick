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

  RecordingListTile({
    super.key,
    required this.recording,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(recording.name.value),
      subtitle: Text(DateFormat('yyyy-MM-dd').format(recording.createdAt.value)),
      trailing: sharedState.currentPath.value == recording.path && sharedState.isLoading.value == true ?
      const LoadingIndicator(
        indicatorType: Indicator.ballClipRotateMultiple,
        colors: [Color(0xFFE4E4E4)],
      ) : null,
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
