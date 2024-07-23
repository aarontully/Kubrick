import 'package:get/get.dart';
import 'package:kubrick/models/metadata_class.dart';

class Recording extends GetxController {
  String? uploadId;
  String? transcriptionId;
  Map<String, dynamic>? transcription;
  RxString path = ''.obs;
  Rx<DateTime> createdAt = DateTime.now().obs;
  RxString name = ''.obs;
  RxString status = ''.obs;
  Rx<Metadata> metadata = Metadata().obs;

  Recording({required String path, required DateTime createdAt, required String name,
  String status = 'Not Uploaded', this.uploadId, this.transcriptionId, this.transcription, Metadata? metadata}) {
    this.path.value = path;
    this.createdAt.value = createdAt;
    this.name.value = name;
    this.status.value = status;
    this.metadata.value = metadata ?? this.metadata.value;
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
      'metadata': metadata.value.toMap(),
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
      metadata: Metadata.fromMap(map['metadata'] as Map<String, dynamic>),
    );
  }
}