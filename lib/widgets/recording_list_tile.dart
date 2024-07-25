import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/screens/recording_info.dart';

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
      subtitle:
          Text(DateFormat('yyyy-MM-dd').format(recording.createdAt.value)),
      trailing: Obx(() => SizedBox(
            width: 50,
            child: sharedState.isProcessing.value
                ? const LinearProgressIndicator(value: 0.5)
                : recording.status.value == 'Uploaded'
                    ? const Icon(Icons.cloud_done)
                    : const Icon(Icons.cloud_off),
          )),
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordingInfoScreen(
              recording: recording,
            ),
          ),
        );
      },
    );
  }
}
