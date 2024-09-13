import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/file_api_service.dart';

class SyncService {
  FileApiService fileApiService = FileApiService();

  Future<void> syncRecordings() async {
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
      } else {
        // Remote recording exists locally
        print('Remote recording exists locally');
      }
    }

    for (final localRecording in localRecordings) {
      final remoteRecording = remoteRecordingMap[localRecording.uploadId];

      if (remoteRecording == null) {
        // Local recording does not exist remotely
        // need to upload file to remote db
      } else {
        // Local recording exists remotely
      }
    }
  }
}