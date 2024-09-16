import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/metadata_class.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yaml/yaml.dart';

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

  static Future<int> getAppVersion() async {
    final pubspec = await rootBundle.loadString('pubspec.yaml');
    final pubspecMap = loadYaml(pubspec);
    final version = pubspecMap['version'] as String;
    final versionParts = version.split('.');
    final versionString = versionParts.join('');
    return int.parse(versionString);
  }

  static Future<Database> initDatabase() async {
    final version = await getAppVersion();
    return openDatabase(
      join(await getDatabasesPath(), databaseName),
      version: version,
      onCreate: (db, version) {
        return db.transaction((txn) async {
          await txn.execute(
            "CREATE TABLE $tableRecordings (id INTEGER PRIMARY KEY, path TEXT, createdAt TEXT, name TEXT, status TEXT, uploadId TEXT, transcriptionId TEXT, transcription TEXT, metadata TEXT,speakers TEXT, user_id TEXT)",
          );
        });
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 15) { // version 0.1.5
          db.execute(
            "ALTER TABLE $tableRecordings ADD COLUMN speakers TEXT",
          );
          db.execute(
            "ALTER TABLE $tableRecordings ADD COLUMN user_id TEXT",
          );
        }
      },
    );
  }

  static Future<void> insertRecording(Recording recording) async {
    final db = await initDatabase();

    final transcriptionJson = jsonEncode(recording.transcription);
    final metadataJson = jsonEncode(recording.metadata.value.toMap());
    final speakersJson = jsonEncode(recording.speakers);

    await db.insert(
      tableRecordings,
      recording.toMap()
        ..['transcription'] = transcriptionJson
        ..['metadata'] = metadataJson
        ..['speakers'] = speakersJson,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Recording>> getRecordings() async {
    final db = await initDatabase();
    SharedState sharedState = Get.find<SharedState>();
    String userId = sharedState.currentUser.value;

    final List<Map<String, dynamic>> maps = await db.query(tableRecordings, where: 'user_id = ?', whereArgs: [userId]);

    return List.generate(maps.length, (index) {
      final transcription = jsonDecode(maps[index]['transcription']);
      final metadataMap = jsonDecode(maps[index]['metadata']);
      final metadata = Metadata.fromMap(metadataMap);
      final speakersJson = maps[index]['speakers'];
      final speakers = speakersJson != null ? jsonDecode(speakersJson) as List<dynamic> : <dynamic>[];

      return Recording(
        path: maps[index][columnPath],
        createdAt: DateTime.parse(maps[index][columnCreatedAt]),
        name: maps[index][columnName],
        status: maps[index][columnStatus],
        uploadId: maps[index][columnUploadId],
        transcription: transcription,
        transcriptionId: maps[index]['transcriptionId'],
        metadata: metadata,
        speakers: speakers,
        user_id: maps[index]['user_id'],
      );
    });
  }

  static Future<void> updateRecording(Recording recording) async {
    final db = await initDatabase();

    final transcriptionJson = jsonEncode(recording.transcription);
    final metadataJson = jsonEncode(recording.metadata.value.toMap());
    final speakersJson = jsonEncode(recording.speakers);

    try {
      await db.update(
        tableRecordings,
        recording.toMap()
          ..['transcription'] = transcriptionJson
          ..['metadata'] = metadataJson
          ..['speakers'] = speakersJson,
        where: 'path = ?',
        whereArgs: [recording.path.value],
      );
    } catch (e) {
      print('Updating issue: $e');
    }

    await db.close();
  }

  static Future<void> deleteRecording(Recording recording) async {
    final db = await initDatabase();

    await db.delete(
      tableRecordings,
      where: 'path = ?',
      whereArgs: [recording.path.value],
    );

    print('Local recording deleted: ${recording.path.value}');

    await db.close();
  }
}