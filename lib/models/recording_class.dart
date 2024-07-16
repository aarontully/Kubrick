import 'package:get/get.dart';

class Recording extends GetxController {
  String? uploadId;
  String? transcriptionId;
  Map<String, dynamic>? transcription;
  RxString path = ''.obs;
  Rx<DateTime> createdAt = DateTime.now().obs;
  RxString name = ''.obs;
  RxString status = ''.obs;

  Recording({required String path, required DateTime createdAt, required String name, String status = 'Not Uploaded', this.uploadId, this.transcriptionId, this.transcription}){
    this.path.value = path;
    this.createdAt.value = createdAt;
    this.name.value = name;
    this.status.value = status;
  }

  Map<String, dynamic> toMap() {
    return {
      'uploadId': uploadId,
      'path': path.value,
      'createdAt': createdAt.value.toIso8601String(),
      'name': name.value,
      'status': status.value,
      'transcriptionId': transcriptionId ,
      'transcription':  transcription,
    };
  }

  static Recording fromMap(Map<String, dynamic> map) {
    return Recording(
      path: map['path'],
      createdAt: DateTime.parse(map['createdAt']),
      name: map['name'],
      status: map['status'] ?? 'Not Uploaded',
      uploadId: map['uploadId'],
      transcriptionId: map['transcriptionId'],
      transcription: map['transcription'],
    );
  }
}