import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'table_definitions.dart';

class DatabaseHelper {
  static const String _databaseName = 'mahjong_scoreboard.db';
  static const int _databaseVersion = 1;
  
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
    // 将来的なマイグレーション処理をここに追加
    if (oldVersion < 2) {
      // 例: 新しいカラムの追加
      // await db.execute('ALTER TABLE games ADD COLUMN new_column TEXT');
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