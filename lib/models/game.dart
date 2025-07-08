import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database/database_helper.dart';

class Game {
  final int? id;
  final String title;
  final int basePoint;
  final double umaOka;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Game({
    this.id,
    required this.title,
    required this.basePoint,
    required this.umaOka,
    this.memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Game copyWith({
    int? id,
    String? title,
    int? basePoint,
    double? umaOka,
    String? memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      basePoint: basePoint ?? this.basePoint,
      umaOka: umaOka ?? this.umaOka,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'base_point': basePoint,
      'uma_oka': umaOka,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      title: map['title'] as String,
      basePoint: map['base_point'] as int,
      umaOka: map['uma_oka'] as double,
      memo: map['memo'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Game(id: $id, title: $title, basePoint: $basePoint, umaOka: $umaOka, memo: $memo)';
  }
}

class GameRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ゲームを作成
  Future<Game> createGame(Game game) async {
    final db = await _dbHelper.database;
    
    final id = await db.insert(
      'games',
      game.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return game.copyWith(id: id);
  }

  // 全ゲームを取得
  Future<List<Game>> getAllGames() async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) => Game.fromMap(maps[i]));
  }

  // IDでゲームを取得
  Future<Game?> getGameById(int id) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Game.fromMap(maps.first);
    }
    return null;
  }

  // ゲームを更新
  Future<int> updateGame(Game game) async {
    final db = await _dbHelper.database;
    
    return await db.update(
      'games',
      game.toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  // ゲームを削除
  Future<int> deleteGame(int id) async {
    final db = await _dbHelper.database;
    
    return await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// Riverpod Provider
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

final gamesProvider = FutureProvider<List<Game>>((ref) async {
  final repository = ref.read(gameRepositoryProvider);
  return await repository.getAllGames();
});

final currentGameProvider = StateProvider<Game?>((ref) => null); 