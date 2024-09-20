import 'package:get/get.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/recording_service.dart';
import 'package:kubrick/services/sync_service.dart';

class RecordingsController extends GetxController {
  RxList<Recording> recordings = <Recording>[].obs;
  RecordingService recordingService = RecordingService();

  @override
  void onInit() {
    super.onInit();
    fetchRecordings();
  }

  Future fetchRecordings() async {
    bool hasNetwork = await recordingService.hasNetwork();
    if(hasNetwork) {
      await SyncService().syncRecordings();
    }
    List<Recording> fetchedRecordings = await DatabaseHelper.getRecordings();
    if (fetchedRecordings.isNotEmpty) {
      recordings.clear();
      recordings.addAll(fetchedRecordings.reversed.toList());
    }
  }

  void updateRecording(Recording recording) {
    int index = recordings.indexWhere((element) => element.path.value == recording.path.value);
    recordings[index] = recording;
    update();
  }
}