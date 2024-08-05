import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:path/path.dart' as path;

AlertDialog createEditRecordingDialog(BuildContext context, Recording recording) {
  final oldFilename = recording.name.value;
  final shootdayController = TextEditingController(text: recording.metadata.value.shoot_day);
  final interviewDayController = TextEditingController(text: recording.metadata.value.interview_day);
  final contestantController = TextEditingController(text: recording.metadata.value.contestant);
  final cameraController = TextEditingController(text: recording.metadata.value.camera);
  final audioController = TextEditingController(text: recording.metadata.value.audio);
  final producerController = TextEditingController(text: recording.metadata.value.producer);

  void updateRecording(String newShootDay, String newInterviewDay, String newContestant, String newCamera, String newAudio, String newProducer) async {
    recording.metadata.value.shoot_day = newShootDay;
    recording.metadata.value.interview_day = newInterviewDay;
    recording.metadata.value.contestant = newContestant;
    recording.metadata.value.camera = newCamera;
    recording.metadata.value.audio = newAudio;
    recording.metadata.value.producer = newProducer;

    await DatabaseHelper.updateRecording(recording);
    Get.find<RecordingsController>().updateRecording(recording);
  }

  String generateNewFilename(String oldFilename, String shootDay, String interviewDay, String contestant, String camera, String audio, String producer) {
    final parts = oldFilename.split('_');
    final hour = parts[4];
    final minute = parts[5];
    final extension = path.extension(oldFilename);

    final newFilename = '${shootDay.toUpperCase()}_${contestant.toUpperCase()}_${camera.toUpperCase()}_${audio.toUpperCase()}_${hour}_${minute}_${producer.toUpperCase()}$extension';
    return newFilename;
  }

  return AlertDialog(
    title: const Text('Edit Recording'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: shootdayController,
          decoration: const InputDecoration(labelText: 'Shoot Day'),
          onChanged: (value) => shootdayController.text = value.toUpperCase(),
        ),
        TextField(
          controller: interviewDayController,
          decoration: const InputDecoration(labelText: 'Interview Day'),
          onChanged: (value) => interviewDayController.text = value.toUpperCase(),
        ),
        TextField(
          controller: contestantController,
          decoration: const InputDecoration(labelText: 'Contestant'),
          onChanged: (value) => contestantController.text = value.toUpperCase(),
        ),
        TextField(
          controller: cameraController,
          decoration: const InputDecoration(labelText: 'Camera'),
          onChanged: (value) => cameraController.text = value.toUpperCase(),
        ),
        TextField(
          controller: audioController,
          decoration: const InputDecoration(labelText: 'Audio'),
          onChanged: (value) => audioController.text = value.toUpperCase(),
        ),
        TextField(
          controller: producerController,
          decoration: const InputDecoration(labelText: 'Producer'),
          onChanged: (value) => producerController.text = value.toUpperCase(),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          final newFilename = generateNewFilename(
            oldFilename,
            shootdayController.text,
            interviewDayController.text,
            contestantController.text,
            cameraController.text,
            audioController.text,
            producerController.text
          );
          recording.name.value = newFilename;
          updateRecording(
            shootdayController.text,
            interviewDayController.text,
            contestantController.text,
            cameraController.text,
            audioController.text,
            producerController.text
          );
          Navigator.of(context).pop();
        },
        child: const Text('Save'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
    ],
  );
}