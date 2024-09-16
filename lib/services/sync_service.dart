import 'dart:io';

import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/file_api_service.dart';
import 'package:kubrick/services/transcription_api_service.dart';
import 'package:path/path.dart' as p;

class SyncService {
  FileApiService fileApiService = FileApiService();

  Future<List<Recording>> syncRecordings() async {
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
        final fetchedFile = await fileApiService.getFileInfo(remoteRecording['id']);
        await TranscriptionApiService().getTranscriptions(fetchedFile.uploadId!);
        fetchedFile.status.value = 'Uploaded';
        await DatabaseHelper.insertRecording(fetchedFile);
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

        final file = File(localRecording.path.value);
        final fileSize = await file.length();
        const chunkSize = 1024 * 1024; //1MB
        final chunkCount = (fileSize / chunkSize).ceil();
        final fileName = p.basename(localRecording.path.value);

        await fileApiService.initUpload(chunkCount, fileName, chunkSize,localRecording);
      } else {
        // Local recording exists remotely
        print('Local recording exists remotely...doing nothing');
      }
    }

    final updatedLocalRecordings = await DatabaseHelper.getRecordings();

    return updatedLocalRecordings;
  }
}