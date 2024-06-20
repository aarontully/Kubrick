import 'dart:io';

import 'package:intl/intl.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/ai_api_service.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/utils/chunk_transformer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class RecordingService {
  final AudioRecorder record = AudioRecorder();
  final Uuid uuid = const Uuid();
  final DatabaseHelper databaseHelper = DatabaseHelper();
  final ApiService apiService =ApiService();

  Future<String> startRecording() async {
    if (await record.hasPermission()) {
      Directory directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}/${uuid.v1()}.aac';
      await record.start(const RecordConfig(), path: path);
      return path;
    }
    throw Exception('Could not start recording');
  }

  Future<Recording?> stopRecording() async {
    String? path = await record.stop();

    if (path != null) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('EEEE \'at\' HH:mm').format(now);

      Recording recording = Recording(
        path: path,
        createdAt: now,
        name: formattedDate,
      );

      await DatabaseHelper.insertRecording(recording);
      await transcribeRecording(recording);
      return recording;
    }
    return null;
  }

  Future<void> transcribeRecording(Recording recording) async {
    final file = File(recording.path.value);
    final fileSize = await file.length();
    const chunkSize = 1024 * 1024; //1MB
    final chunkCount = (fileSize / chunkSize).ceil();
    final fileName = p.basename(recording.path.value);

    final uploadId = await apiService.initUpload(chunkCount, fileName, fileSize);

    final fileStream = file.openRead();
    int i = 0;
    await for(var chunk in fileStream.transform(ChunkTransformer(chunkSize))) {
      await apiService.uploadChunk(uploadId, i, chunk.length, chunk);
      i++;
    }

    await apiService.completeUpload(uploadId);

    //start transcription
    //Data data = await apiService.fetchTranscription(uploadId, chunkCount, chunkSize, fileName);
    //print(data.file.name);
  }
}