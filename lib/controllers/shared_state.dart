import 'package:get/get.dart';
import 'package:kubrick/models/recording_class.dart';

class SharedState extends GetxController {
  RxBool isLoading = false.obs;
  RxString currentPath = ''.obs;
  RxBool isProcessing = false.obs;
  Rx<Recording?> currentRecording = Rx<Recording?>(null);

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void setCurrentPath(String path) {
    currentPath.value = path;
  }

  void setProcessing(bool value) {
    isProcessing.value = value;
  }

  void setCurrentRecording(Recording? recording){
    currentRecording.value = recording;
  }
}