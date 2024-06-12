class Data {
  final MyFile file;

  Data({required this.file});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      file: MyFile.fromJson(json['file']),
    );
  }
}

class MyFile {
  final int chunks;
  final String createdAt;
  final String deletedAt;
  final String extension;
  final String id;
  final String name;
  final int size;
  final String updatedAt;
  final String uploadedAt;
  final Uploader uploader;

  MyFile({required this.chunks, required this.createdAt, required this.deletedAt, required this.extension, required this.id, required this.name, required this.size, required this.updatedAt, required this.uploadedAt, required this.uploader});

  factory MyFile.fromJson(Map<String, dynamic> json) {
    return MyFile(
      chunks: json['chunks'],
      createdAt: json['created_at'],
      deletedAt: json['deleted_at'],
      extension: json['extension'],
      id: json['id'],
      name: json['name'],
      size: json['size'],
      updatedAt: json['updated_at'],
      uploadedAt: json['uploaded_at'],
      uploader: Uploader.fromJson(json['uploader']),
    );
  }
}

class Uploader {
  final String createdAt;
  final String email;
  final String id;
  final String name;

  Uploader({required this.createdAt, required this.email, required this.id, required this.name});

  factory Uploader.fromJson(Map<String, dynamic> json) {
    return Uploader(
      createdAt: json['created_at'],
      email: json['email'],
      id: json['id'],
      name: json['name'],
    );
  }
}