import 'dart:io';

import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/metadata_class.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/file_api_service.dart';
import 'package:kubrick/services/transcription_api_service.dart';
import 'package:path/path.dart' as p;

class SyncService {
  FileApiService fileApiService = FileApiService();
  RecordingsController recordingsController = RecordingsController();
  SharedState sharedState = Get.find<SharedState>();

  Future syncRecordings() async {
    if(sharedState.isProcessing.value) {
      return;
    }

    sharedState.setProcessing(true);

    final remoteRecordings = await fileApiService.getRemoteFiles();
    final localRecordings = await DatabaseHelper.getRecordings();

    final localRecordingMap = Map.fromEntries(localRecordings.map((recording) => MapEntry(recording.uploadId, recording)));
    final remoteRecordingMap = Map.fromEntries(remoteRecordings.map((recording) => MapEntry(recording['id'], recording)));

    for (final remoteRecording in remoteRecordings) {
      final localRecording = localRecordingMap[remoteRecording['id']];

      if (localRecording == null) {
        // Remote recording does not exist locally
        // need to download file from remote db
        print('Downloading file from remote db');

        Recording newRecording = Recording(
          path: '',
          name: remoteRecording['name'],
          uploadId: remoteRecording['id'],
          createdAt: DateTime.parse(remoteRecording['created_at']),
          user_id: remoteRecording['uploader_id'],
        );

        newRecording.metadata.value = remoteRecording['metadata'] != null ? Metadata.fromMap(remoteRecording['metadata']) : Metadata();
        String returnedPath = await fileApiService.downloadFile(newRecording);
        newRecording.path.value = returnedPath;
        await TranscriptionApiService().getAllTranscriptions(newRecording);

        newRecording.status.value = 'Uploaded';

        //final fetchedFile = await fileApiService.getFileInfo(remoteRecording['id']);
        await DatabaseHelper.insertRecording(newRecording);
      } else {
        // Remote recording exists locally
        print('Remote recording exists locally...doing nothing');
      }
    }

    for (final localRecording in localRecordings) {
      final remoteRecording = remoteRecordingMap[localRecording.uploadId];

      if (remoteRecording == null) {
        // Local recording does not exist remotely
        // need to upload file to remote db
        print('Uploading file to remote db');

        final file = File(localRecording.path.value);

      if( await file.exists()) {
          final file = File(localRecording.path.value);
          final fileSize = await file.length();
          const chunkSize = 1024 * 1024; //1MB
          final chunkCount = (fileSize / chunkSize).ceil();
          final fileName = p.basename(localRecording.path.value);

          await fileApiService.initUpload(chunkCount, fileName, chunkSize,localRecording);
          print('Upload to remote db complete');
        }
      } else {
        // Local recording exists remotely
        print('Local recording exists remotely...doing nothing');
      }
    }

    sharedState.setProcessing(false);
    print('Sync complete');
  }
}