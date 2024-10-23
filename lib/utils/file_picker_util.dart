import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/auth_service.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:kubrick/widgets/metadata_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FilePickerUtil {
  static Uuid uuid = const Uuid();
  static final RecordingService recordingService = RecordingService();

  static Future<void> pickAndSaveFile(BuildContext context) async {
    final sharedState = Get.find<SharedState>();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'm4a',
        'mp4',
        'wav',
        'aac',
        'flac',
        'pcm',
        'ogg',
        'opus',
        'webm'
      ]
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      sharedState.setProcessing(true);
      Directory dir = await getApplicationDocumentsDirectory();
      sharedState.setUploadProgress(0.2);
      final path = dir.path;
      final String ext = p.extension(file.path);
      final newFile = await file.copy('$path/${uuid.v1()}$ext');

      //set metadata
      var metadata = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return buildMetadataDialog(context);
        },
      );

      if (metadata == null) {
        sharedState.setProcessing(false);
        return;
      }

      AuthService authService = AuthService();
      String userId = await authService.getUserId();

      final createdDateTime = await file.lastModified();

      String hours = createdDateTime.hour.toString().padLeft(2, '0');
      String minutes = createdDateTime.minute.toString().padLeft(2, '0');

      Recording addedRecording = Recording(
        path: newFile.path,
        createdAt: createdDateTime,
        name: '${metadata.shoot_day}_${metadata.interview_day}_${metadata.contestant}_${metadata.camera}_${metadata.audio}_${hours}_${minutes}_${metadata.producer}$ext',
        metadata: metadata,
        user_id: userId,
      );

      sharedState.setUploadProgress(0.3);
      await DatabaseHelper.insertRecording(addedRecording);

      Get.find<RecordingsController>().recordings.add(addedRecording);
      Get.find<RecordingsController>().fetchRecordings();

      sharedState.setUploadProgress(0.4);

      final response =
          await recordingService.uploadRecording(addedRecording);
      if (response) {
        addedRecording.status.value = 'Uploaded';
      } else {
        addedRecording.status.value = 'Local';
      }
      addedRecording.status.refresh();
      await DatabaseHelper.updateRecording(addedRecording);

      sharedState.setUploadProgress(0.10);
      sharedState.setProcessing(false);
    }
  }
}
