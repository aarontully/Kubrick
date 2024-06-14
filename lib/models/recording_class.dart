class Recording {
  final String? path;
  final DateTime createdAt;
  final String? name;

  Recording({required this.path, required this.createdAt, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'name': name,
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