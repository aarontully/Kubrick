import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kubrick/models/recording_class.dart';

class SharedState extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRecording = false.obs;
  RxString currentPath = ''.obs;
  RxBool isProcessing = false.obs;
  RxBool isConnected = false.obs;
  RxDouble uploadProgress = 0.0.obs;
  Rx<Recording?> currentRecording = Rx<Recording?>(null);

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void setCurrentPath(String path) {
    currentPath.value = path;
  }

  void setProcessing(bool value) {
    isProcessing.value = value;
    update();
  }

  void setUploadProgress(double value) {
    uploadProgress.value = value;
    update();
  }

  void setRecording(bool value) {
    isRecording.value = value;
  }

  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi)) {
        isConnected.value = true;
        return true;
      } else {
        isConnected.value = false;
        return false;
      }
    } catch (e) {
      print('Failed to check connectivity: $e');
      return false;
    }
  }
}