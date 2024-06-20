import 'package:get/get.dart';

class Recording extends GetxController {
  RxString path = ''.obs;
  Rx<DateTime> createdAt = DateTime.now().obs;
  RxString name = ''.obs;

  Recording({required String path, required DateTime createdAt, required String name}) {
    this.path.value = path;
    this.createdAt.value = createdAt;
    this.name.value = name;
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path.value,
      'createdAt': createdAt.value.toIso8601String(),
      'name': name.value,
    };
  }

  static Recording fromMap(Map<String, dynamic> map) {
    return Recording(
      path: map['path'],
      createdAt: DateTime.parse(map['createdAt']),
      name: map['name'],
    );
  }
}