import 'package:sqflite/sqflite.dart';

class Migration001 {
  static const int version = 1;
  static const String description = 'Initial database schema';

  static Future<void> up(Database db) async {
    // Game テーブル作成
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        base_point INTEGER NOT NULL DEFAULT 25000,
        uma_oka REAL NOT NULL DEFAULT 10.0,
        memo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Player テーブル作成
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    // Round テーブル作成
    await db.execute('''
      CREATE TABLE rounds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        round_number INTEGER NOT NULL,
        player_1_score INTEGER,
        player_2_score INTEGER,
        player_3_score INTEGER,
        player_4_score INTEGER,
        player_5_score INTEGER,
        player_6_score INTEGER,
        player_7_score INTEGER,
        player_8_score INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    // インデックス作成
    await db.execute('CREATE INDEX idx_players_game_id ON players (game_id)');
    await db.execute('CREATE INDEX idx_players_order_index ON players (game_id, order_index)');
    await db.execute('CREATE INDEX idx_rounds_game_id ON rounds (game_id)');
    await db.execute('CREATE INDEX idx_rounds_round_number ON rounds (game_id, round_number)');
  }

  static Future<void> down(Database db) async {
    // インデックス削除
    await db.execute('DROP INDEX IF EXISTS idx_rounds_round_number');
    await db.execute('DROP INDEX IF EXISTS idx_rounds_game_id');
    await db.execute('DROP INDEX IF EXISTS idx_players_order_index');
    await db.execute('DROP INDEX IF EXISTS idx_players_game_id');
    
    // テーブル削除
    await db.execute('DROP TABLE IF EXISTS rounds');
    await db.execute('DROP TABLE IF EXISTS players');
    await db.execute('DROP TABLE IF EXISTS games');
  }
} 