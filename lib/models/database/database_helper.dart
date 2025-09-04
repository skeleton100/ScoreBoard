import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'table_definitions.dart';

class DatabaseHelper {
  static const String _databaseName = 'mahjong_scoreboard.db';
  static const int _databaseVersion = 2;
  
  static Database? _database;

  // シングルトンパターン
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // データベース取得
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // データベース初期化
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // データベース作成時の処理
  Future<void> _onCreate(Database db, int version) async {
    // テーブル作成
    for (String createTable in TableDefinitions.createTables) {
      await db.execute(createTable);
    }
  }

  // データベースアップグレード時の処理
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // uma_okaを分割してumaとokaに変更
      await db.execute('ALTER TABLE games ADD COLUMN uma REAL NOT NULL DEFAULT 10.0');
      await db.execute('ALTER TABLE games ADD COLUMN oka REAL NOT NULL DEFAULT 20.0');
      
      // 既存のuma_okaの値をumaとokaにコピー
      await db.execute('''
        UPDATE games 
        SET uma = uma_oka, oka = uma_oka 
        WHERE uma_oka IS NOT NULL
      ''');
      
      // 古いカラムを削除（SQLiteでは直接削除できないため、テーブルを再作成）
      await db.execute('CREATE TEMPORARY TABLE games_backup AS SELECT * FROM games');
      await db.execute('DROP TABLE games');
      await db.execute(TableDefinitions.createGameTable);
      await db.execute('''
        INSERT INTO games (id, title, base_point, uma, oka, memo, created_at, updated_at)
        SELECT id, title, base_point, uma, oka, memo, created_at, updated_at 
        FROM games_backup
      ''');
      await db.execute('DROP TABLE games_backup');
    }
  }

  // データベースを閉じる
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // データベースを削除（開発時のみ使用）
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // データベースの状態を確認
  Future<bool> isDatabaseOpen() async {
    try {
      final db = await database;
      return db.isOpen;
    } catch (e) {
      return false;
    }
  }

  // テーブル一覧を取得
  Future<List<String>> getTableNames() async {
    final db = await database;
    final tables = await db.query('sqlite_master', 
      where: 'type = ?', 
      whereArgs: ['table'],
      columns: ['name']
    );
    return tables.map((table) => table['name'] as String).toList();
  }

  // データベースの行数を取得
  Future<Map<String, int>> getTableRowCounts() async {
    final db = await database;
    final tableNames = await getTableNames();
    Map<String, int> rowCounts = {};
    
    for (String tableName in tableNames) {
      if (tableName != 'sqlite_master') {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
        rowCounts[tableName] = Sqflite.firstIntValue(result) ?? 0;
      }
    }
    
    return rowCounts;
  }
} 