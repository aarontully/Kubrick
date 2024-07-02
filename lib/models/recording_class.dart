import 'package:get/get.dart';

class Recording extends GetxController {
  RxString path = ''.obs;
  Rx<DateTime> createdAt = DateTime.now().obs;
  RxString name = ''.obs;
  RxString status = ''.obs;

  Recording({required String path, required DateTime createdAt, required String name, String status = 'Not Uploaded'}) {
    this.path.value = path;
    this.createdAt.value = createdAt;
    this.name.value = name;
    this.status.value = status;
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path.value,
      'createdAt': createdAt.value.toIso8601String(),
      'name': name.value,
      'status': status.value,
    };
  }

  static Recording fromMap(Map<String, dynamic> map) {
    return Recording(
      path: map['path'],
      createdAt: DateTime.parse(map['createdAt']),
      name: map['name'],
      status: map['status'] ?? 'Not Uploaded',
    );
  }
}