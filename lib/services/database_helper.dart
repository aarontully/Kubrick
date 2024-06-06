import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/models/upload_class.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String databaseName = 'recordings.db';
  static const String tabeRecordings = 'recordings';
  static const String tableUploads = 'uploads';
  static const String columnId = 'id';
  static const String columnPath = 'path';
  static const String columnCreatedAt = 'createdAt';

  static Future<Database> initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), databaseName),
      version: 1,
      onCreate: (db, version) {
        return db.transaction((txn) async {
          await txn.execute(
            "CREATE TABLE $tabeRecordings (id INTEGER PRIMARY KEY, path TEXT, createdAt TEXT)",
          );
          await txn.execute(
            "CREATE TABLE $tableUploads (id INTEGER PRIMARY KEY, recordingPath TEXT, uploadId TEXT, chunkCount INTEGER, uploadedChunks INTEGER, isComplete INTEGER)",
          );
        });
      },
    );
  }

  static Future<void> insertRecording(Recording recording) async {
    final db = await initDatabase();

    await db.insert(
      tabeRecordings,
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.close();
  }

  static Future<List<Recording>> getRecordings() async {
    final db = await initDatabase();
    final List<Map<String, dynamic>> maps = await db.query(tabeRecordings);

    await db.close();

    return List.generate(maps.length, (index) {
      return Recording(
        path: maps[index][columnPath],
        createdAt: DateTime.parse(maps[index][columnCreatedAt]),
      );
    });
  }

  static Future<void> deleteRecording(Recording recording) async {
    final db = await initDatabase();

    await db.delete(
      tabeRecordings,
      where: 'path = ?',
      whereArgs: [recording.path],
    );

    await db.close();
  }

  static Future<void> saveUpload(Upload upload) async {
    final db = await initDatabase();

    await db.insert(
      tableUploads,
      upload.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.close();
  }
}