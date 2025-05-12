// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gestaofacil.db');

    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE vendas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cliente TEXT,
          valor REAL,
          tipo TEXT,
          data TEXT
        )
      ''');
    });
  }
}
