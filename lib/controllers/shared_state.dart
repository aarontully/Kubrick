import 'package:get/get.dart';

class SharedState extends GetxController {
  var isLoading = false.obs;
  var currentPath = ''.obs;

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void setCurrentPath(String path) {
    currentPath.value = path;
  }
}