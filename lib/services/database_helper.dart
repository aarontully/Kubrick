import 'dart:convert';

import 'package:kubrick/models/recording_class.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String databaseName = 'recordings.db';
  static const String tableRecordings = 'recordings';
  static const String tableUploads = 'uploads';
  static const String columnId = 'id';
  static const String columnPath = 'path';
  static const String columnCreatedAt = 'createdAt';
  static const String columnName = 'name';
  static const String columnStatus = 'status';
  static const String columnUploadId = 'uploadId';

  static Future<Database> initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), databaseName),
      version: 1,
      onCreate: (db, version) {
        return db.transaction((txn) async {
          await txn.execute(
            "CREATE TABLE $tableRecordings (id INTEGER PRIMARY KEY, path TEXT, createdAt TEXT, name TEXT, status TEXT, uploadId TEXT, transcriptionId TEXT, transcription TEXT)",
          );
          /* await txn.execute(
            "CREATE TABLE $tableUploads (id INTEGER PRIMARY KEY, recordingPath TEXT, uploadId TEXT, chunkCount INTEGER, uploadedChunks INTEGER, isComplete INTEGER)",
          ); */
        });
      },
    );
  }

  static Future<void> insertRecording(Recording recording) async {
    final db = await initDatabase();

    final transcriptionJson = jsonEncode(recording.transcription);

    await db.insert(
      tableRecordings,
      recording.toMap()..['transcription'] = transcriptionJson,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.close();
  }

  static Future<List<Recording>> getRecordings() async {
    final db = await initDatabase();
    final List<Map<String, dynamic>> maps = await db.query(tableRecordings);

    await db.close();

    return List.generate(maps.length, (index) {
      final transcription = jsonDecode(maps[index]['transcription']);

      return Recording(
        path: maps[index][columnPath],
        createdAt: DateTime.parse(maps[index][columnCreatedAt]),
        name: maps[index][columnName],
        status: maps[index][columnStatus],
        uploadId: maps[index][columnUploadId],
        transcription: transcription,
        transcriptionId: maps[index]['transcriptionId'],
      );
    });
  }

  static Future<void> updateRecording(Recording recording) async {
    final db = await initDatabase();

    final transcriptionJson = jsonEncode(recording.transcription);

    await db.update(
      tableRecordings,
      recording.toMap()..['transcription'] = transcriptionJson,
      where: 'path = ?',
      whereArgs: [recording.path.value],
    );

    await db.close();
  }

  static Future<void> deleteRecording(Recording recording) async {
    final db = await initDatabase();

    await db.delete(
      tableRecordings,
      where: 'path = ?',
      whereArgs: [recording.path.value],
    );

    await db.close();
  }

  /* static Future<void> saveUpload(Upload upload) async {
    final db = await initDatabase();

    await db.insert(
      tableUploads,
      upload.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.close();
  } */
}