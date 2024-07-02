import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FilePickerUtil {
  static Uuid uuid = const Uuid();
  static final RecordingService recordingService = RecordingService();

  static Future<void> pickAndSaveFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if(result != null) {
      File file = File(result.files.single.path!);
      Directory dir = await getApplicationDocumentsDirectory();
      final path = dir.path;
      final String ext = p.extension(file.path);
      final newFile = await file.copy('$path/${uuid.v1()}$ext');
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('EEEE \'at\' HH:mm').format(now);
      Recording addedRecording = Recording(
        path: newFile.path,
        createdAt: now,
        name: formattedDate
      );
      await DatabaseHelper.insertRecording(addedRecording);
      await recordingService.transcribeRecording(addedRecording);
    }
  }
}
