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
  List<dynamic> speakers = [];
  RxString user_id = ''.obs;

  Recording({required String path, required DateTime createdAt, required String name,
  String status = 'Not Uploaded', this.uploadId, this.transcriptionId, this.transcription, Metadata? metadata, List<dynamic>? speakers, String? user_id}) {
    this.path.value = path;
    this.createdAt.value = createdAt;
    this.name.value = name;
    this.status.value = status;
    this.metadata.value = metadata ?? this.metadata.value;
    this.speakers = speakers ?? [];
    this.user_id.value = user_id ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'uploadId': uploadId,
      'path': path.value,
      'createdAt': createdAt.value.toUtc().toIso8601String(),
      'name': name.value,
      'status': status.value,
      'transcriptionId': transcriptionId ,
      'transcription':  transcription,
      'metadata': metadata.value.toMap(),
      'speakers': speakers,
      'user_id': user_id.value,
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
      speakers: map['speakers'] as List<dynamic>?,
      user_id: map['user_id'],
    );
  }
}