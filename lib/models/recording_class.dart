import 'package:get/get.dart';

class Recording extends GetxController {
  String? uploadId;
  String? transcriptionId;
  Map<String, dynamic>? transcription;
  RxString path = ''.obs;
  Rx<DateTime> createdAt = DateTime.now().obs;
  RxString name = ''.obs;
  RxString status = ''.obs;
  Map<String, dynamic> metadata = {};

  Recording({required String path, required DateTime createdAt, required String name,
  String status = 'Not Uploaded', this.uploadId, this.transcriptionId, this.transcription, Map<String, dynamic>? metadata}) {
    this.path.value = path;
    this.createdAt.value = createdAt;
    this.name.value = name;
    this.status.value = status;
    this.metadata = metadata ?? this.metadata;
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
      'metadata': metadata,
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
      metadata: map['metadata'] != null ? map['metadata'] as Map<String, dynamic> : {},
    );
  }
}