class Recording {
  final String? path;
  final DateTime createdAt;

  Recording({required this.path, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Recording fromMap(Map<String, dynamic> map) {
    return Recording(
      path: map['path'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}