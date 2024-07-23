import 'package:get/get.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';

class RecordingsController extends GetxController {
  RxList<Recording> recordings = <Recording>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRecordings();
  }

  Future fetchRecordings() async {
    List<Recording> fetchedRecordings = await DatabaseHelper.getRecordings();
    if (fetchedRecordings.isNotEmpty) {
      recordings.clear();
      recordings.addAll(fetchedRecordings);
    }
  }

  void updateRecording(Recording recording) {
    int index = recordings.indexWhere((element) => element.path.value == recording.path.value);
    recordings[index] = recording;
    update();
  }
}