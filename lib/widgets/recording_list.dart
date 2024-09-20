
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/file_api_service.dart';
import 'package:kubrick/widgets/edit_recording_dialog.dart';
import 'package:kubrick/widgets/recording_list_tile.dart';

class RecordingList extends StatelessWidget {
  final RxList<Recording> recordings;
  final Function(Recording) onPlay;
  final Function(Recording) onDelete;

  const RecordingList({
    super.key,
    required this.recordings,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
      itemCount: recordings.length,
      itemBuilder: (context, index) {
        final recording = recordings[index];
        return Dismissible(
          key: Key(recording.path.value),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if(direction == DismissDirection.endToStart) {
              return await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Delete Recording'),
                    content: const Text('Are you sure you want to delete this recording?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );
            } else {
              bool? result = await showDialog(
                context: context,
                builder: (context) => createEditRecordingDialog(context, recording),
              );
              return result ?? false;
            }
          },
          onDismissed: (direction) async {
            var fileApiService = FileApiService();
            if(recording.status.value == 'Uploaded') {
              await fileApiService.deleteFile(recording.uploadId!);
              await DatabaseHelper.deleteRecording(recording);
            } else {
              await DatabaseHelper.deleteRecording(recording);
            }
            recordings.removeAt(index);
            Get.find<RecordingsController>().update();
          },
          background: Container(
            color: Colors.orange,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16.0),
            child: const Icon(Icons.edit),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16.0),
            child: const Icon(Icons.delete),
          ),
          child: RecordingListTile(recording: recording),
        );
      },
    ));
  }
}