import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/history_record.dart';

class HistoryStore {
  static Database? _db;

  static Future<Database> _getDB() async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'apkjiagu.db');
    _db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, v) async {
          await db.execute('''
            CREATE TABLE history (
              id TEXT PRIMARY KEY,
              fileName TEXT NOT NULL,
              filePath TEXT NOT NULL,
              originalSize INTEGER NOT NULL,
              outputSize INTEGER,
              createdAt TEXT NOT NULL,
              finishedAt TEXT,
              packageName TEXT,
              versionName TEXT,
              versionCode INTEGER,
              outputPath TEXT,
              status TEXT NOT NULL,
              errorMessage TEXT
            )
          ''');
          await db.execute(
              'CREATE INDEX idx_history_created ON history(createdAt DESC)');
        },
      ),
    );
    return _db!;
  }

  static Future<String> insert(HistoryRecord r) async {
    final db = await _getDB();
    await db.insert('history', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return r.id;
  }

  static Future<void> update(HistoryRecord r) async {
    final db = await _getDB();
    await db.update('history', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  static Future<List<HistoryRecord>> list() async {
    final db = await _getDB();
    final rows = await db.query('history', orderBy: 'createdAt DESC');
    return rows.map(HistoryRecord.fromMap).toList();
  }

  static Future<void> delete(String id) async {
    final db = await _getDB();
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAll() async {
    final db = await _getDB();
    await db.delete('history');
  }
}
