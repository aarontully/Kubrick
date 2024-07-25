import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SharedState extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRecording = false.obs;
  RxString currentPath = ''.obs;
  RxBool isProcessing = false.obs;
  RxBool isConnected = false.obs;
  RxDouble uploadProgress = 0.0.obs;

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void setCurrentPath(String path) {
    currentPath.value = path;
  }

  void setProcessing(bool value) {
    isProcessing.value = value;
  }

  void setUploadProgress(double value) {
    uploadProgress.value = value;
  }

  void setRecording(bool value) {
    isRecording.value = value;
  }

  Future<bool> checkConnectivity() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi)) {
      isConnected.value = true;
      return true;
    } else {
      isConnected.value = false;
      return false;
    }
  }
}