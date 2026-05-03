import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../constants/app_constants.dart';
import '../../features/kid/models/chat_message.dart';

// ─────────────────────────────────────────────
//  BASE DE DATOS LOCAL — SQLite
//  Solo almacena el historial de chat del NPC
//  Razón: las conversaciones son privadas,
//  no deben salir del dispositivo
//  El cuidador NO tiene acceso a esta DB
// ─────────────────────────────────────────────
class LocalDatabase {
  LocalDatabase._();

  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.localDbName);

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableChatMessages} (
        id          TEXT PRIMARY KEY,
        profile_id  TEXT NOT NULL,
        content     TEXT NOT NULL,
        is_from_user INTEGER NOT NULL DEFAULT 0,
        trigger_type TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    // Índice para búsqueda rápida por perfil
    await db.execute('''
      CREATE INDEX idx_chat_profile
      ON ${AppConstants.tableChatMessages}(profile_id, created_at)
    ''');
  }

  // ─────────────────────────────────────────────
  //  OPERACIONES DE CHAT
  // ─────────────────────────────────────────────

  /// Insertar un mensaje nuevo
  static Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      AppConstants.tableChatMessages,
      message.toLocalDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtener historial de un perfil (más recientes primero)
  static Future<List<ChatMessage>> getHistory({
    required String profileId,
    int limit = AppConstants.localChatHistoryLimit,
  }) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableChatMessages,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    // Invertir para orden cronológico
    return rows.reversed
        .map((row) => ChatMessage.fromLocalDb(row))
        .toList();
  }

  /// Contar mensajes de un perfil (para onboarding: primer chat)
  static Future<int> countMessages(String profileId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableChatMessages} WHERE profile_id = ?',
      [profileId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Borrar historial de un perfil
  static Future<void> clearHistory(String profileId) async {
    final db = await database;
    await db.delete(
      AppConstants.tableChatMessages,
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }

  /// Cerrar la base de datos
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
