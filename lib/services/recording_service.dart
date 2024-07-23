import 'dart:io';

import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/file_api_service.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/transcription_api_service.dart';
import 'package:kubrick/utils/chunk_transformer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

import '../controllers/shared_state.dart';

class RecordingService {
  final AudioRecorder record = AudioRecorder();
  final Uuid uuid = const Uuid();
  final DatabaseHelper databaseHelper = DatabaseHelper();
  final FileApiService apiService = FileApiService();
  final TranscriptionApiService transcriptionService = TranscriptionApiService();
  final sharedState = Get.find<SharedState>();

  Future<String> startRecording(Map<String, dynamic> metadata) async {
    if (await record.hasPermission()) {
      Directory directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}/${metadata['shoot_day']}_${metadata['contestant']}_${metadata['camera']}_${metadata['audio']}_${metadata['timecode'][0]}_${metadata['timecode'][1]}_${metadata['timecode'][2]}_${metadata['producer']}.m4a';
      await record.start(const RecordConfig(), path: path);
      print(path);
      return path;
    }
    throw Exception('Could not start recording');
  }

  Future<Recording?> stopRecording(Map<String, dynamic> metadata) async {
    String? path = await record.stop();

    if (path != null) {
      DateTime now = DateTime.now();
      String fileName = p.basename(path);

      Recording recording = Recording(
        path: path,
        createdAt: now,
        name: fileName,
      );

      await DatabaseHelper.insertRecording(recording);

      Get.find<RecordingsController>().recordings.add(recording);
      Get.find<RecordingsController>().fetchRecordings();

      final response = await transcribeRecording(recording);
      if(response) {
        recording.status.value = 'Uploaded';
        await DatabaseHelper.updateRecording(recording);
      }

      return recording;
    }
    return null;
  }

  Future<bool> transcribeRecording(Recording recording) async {
    final file = File(recording.path.value);
    final fileSize = await file.length();
    const chunkSize = 1024 * 1024; //1MB
    final chunkCount = (fileSize / chunkSize).ceil();
    final fileName = p.basename(recording.path.value);

    final uploadId = await apiService.initUpload(chunkCount, fileName, fileSize);
    print('recording service ' + uploadId);
    recording.uploadId = uploadId;
    await DatabaseHelper.updateRecording(recording);

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

      final transcriptionId = await transcriptionService.postTranscription(uploadId);
      recording.transcriptionId = transcriptionId;
      await DatabaseHelper.updateRecording(recording);

      final transcriptionResponse = await transcriptionService.pollTranscription(uploadId, transcriptionId);
      recording.transcription = transcriptionResponse;
      await DatabaseHelper.updateRecording(recording);

      return true;

    } catch (e) {
      throw Exception(e);
    }
  }
}