import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/models/metadata_class.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/auth_service.dart';
import 'package:kubrick/services/file_api_service.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/transcription_api_service.dart';
import 'package:kubrick/utils/chunk_transformer.dart';
import 'package:path/path.dart' as p;

import '../controllers/shared_state.dart';

class RecordingService {
  final FileApiService apiService = FileApiService();
  final TranscriptionApiService transcriptionService =
      TranscriptionApiService();
  final sharedState = Get.find<SharedState>();

  Future<bool> hasNetwork() async {
    try {
      // This is disgusting, but it works for now
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<Recording?> stopRecording(Metadata metadata, String? path) async {
    sharedState.setProcessing(true);
    sharedState.setUploadProgress(0.1);

    if (path != null) {
      DateTime now = DateTime.now();
      String fileName = p.basename(path);
      AuthService authService = AuthService();
      String userId = await authService.getUserId();

      Recording recording = Recording(
        path: path,
        createdAt: now,
        name: fileName,
        metadata: metadata,
        user_id: userId,
        status: 'Local',
      );

      sharedState.setCurrentRecording(recording.path.value);
      sharedState.setUploadProgress(0.3);

      await DatabaseHelper.insertRecording(recording);
      Get.find<RecordingsController>().fetchRecordings();

      sharedState.setUploadProgress(0.4);

      // janky way of dealing with this, try implement connectivity_plus
      final isOnline = await hasNetwork();

      if (isOnline) {
        final response = await uploadRecording(recording);
        if (response) {
          recording.status.value = 'Uploaded';
          await DatabaseHelper.updateRecording(recording);
        }
      }

      sharedState.setUploadProgress(0.10);
      sharedState.setProcessing(false);
      sharedState.setCurrentRecording('');
      return recording;
    }
    return null;
  }

  Future<bool> uploadRecording(Recording recording) async {
    final file = File(recording.path.value);
    final fileSize = await file.length();
    const chunkSize = 1024 * 1024; //1MB
    final chunkCount = (fileSize / chunkSize).ceil();
    final fileName = p.basename(recording.path.value);

    sharedState.setUploadProgress(0.5);

    final uploadId =
        await apiService.initUpload(chunkCount, fileName, fileSize, recording);
    print('recording service $uploadId');
    recording.uploadId = uploadId;
    await DatabaseHelper.updateRecording(recording);

    sharedState.setUploadProgress(0.6);

    // create a filestream for reading
    final fileStream = file.openRead();
    final transformer = ChunkTransformer(chunkSize);

    // iterate through each chunk and upload to the server.
    try {
      int chunkindex = 1;
      await for (var chunk in fileStream.transform(transformer)) {
        await apiService.uploadChunk(uploadId, chunkindex, chunk.length, chunk);
        chunkindex++;
      }

      await apiService.completeUpload(uploadId);
      sharedState.setUploadProgress(0.7);

      final transcriptionId =
          await transcriptionService.postTranscription(uploadId);
      recording.transcriptionId = transcriptionId;
      await DatabaseHelper.updateRecording(recording);

      sharedState.setUploadProgress(0.8);

      final transcriptionResponse = await transcriptionService
          .pollTranscription(uploadId, transcriptionId);
      recording.transcription = transcriptionResponse;
      await DatabaseHelper.updateRecording(recording);

      sharedState.setUploadProgress(0.9);

      return true;
    } catch (e) {
      print('Failed to transcribe recording: $e');
      sharedState.setUploadProgress(0.10);
      sharedState.setProcessing(false);
      sharedState.setCurrentRecording('');
      return false;
    }
  }
}
