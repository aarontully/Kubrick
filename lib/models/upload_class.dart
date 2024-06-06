class Upload {
  final String id;
  final String recordingPath;
  final String uploadId;
  int chunkCount;
  int uploadedChunks;
  bool isComplete;

  Upload({
    required this.id,
    required this.recordingPath,
    required this.uploadId,
    this.chunkCount = 0,
    this.uploadedChunks = 0,
    this.isComplete = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recordingPath': recordingPath,
      'uploadId': uploadId,
      'chunkCount': chunkCount,
      'uploadedChunks': uploadedChunks,
      'isComplete': isComplete ? 1 : 0,
    };
  }

  static Upload fromMap(Map<String, dynamic> map) {
    return Upload(
      id: map['id'],
      recordingPath: map['recordingPath'],
      uploadId: map['uploadId'],
      chunkCount: map['chunkCount'],
      uploadedChunks: map['uploadedChunks'],
      isComplete: map['isComplete'] == 1,
    );
  }
}