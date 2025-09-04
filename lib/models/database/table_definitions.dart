class TableDefinitions {
  // Game テーブル定義
  static const String createGameTable = '''
    CREATE TABLE games (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      base_point INTEGER NOT NULL DEFAULT 25000,
      uma REAL NOT NULL DEFAULT 10.0,
      oka REAL NOT NULL DEFAULT 20.0,
      memo TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  // Player テーブル定義
  static const String createPlayerTable = '''
    CREATE TABLE players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      game_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      order_index INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
    )
  ''';

  // Round テーブル定義
  static const String createRoundTable = '''
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
  ''';

  // インデックス定義
  static const String createIndexes = '''
    CREATE INDEX idx_players_game_id ON players (game_id);
    CREATE INDEX idx_players_order_index ON players (game_id, order_index);
    CREATE INDEX idx_rounds_game_id ON rounds (game_id);
    CREATE INDEX idx_rounds_round_number ON rounds (game_id, round_number);
  ''';

  // テーブル削除用（開発時のみ使用）
  static const List<String> dropTables = [
    'DROP TABLE IF EXISTS rounds',
    'DROP TABLE IF EXISTS players',
    'DROP TABLE IF EXISTS games',
  ];

  // 全テーブル作成
  static const List<String> createTables = [
    createGameTable,
    createPlayerTable,
    createRoundTable,
    createIndexes,
  ];
} 