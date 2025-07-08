import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database/database_helper.dart';

class Player {
  final int? id;
  final int gameId;
  final String name;
  final int orderIndex;
  final DateTime createdAt;

  Player({
    this.id,
    required this.gameId,
    required this.name,
    required this.orderIndex,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Player copyWith({
    int? id,
    int? gameId,
    String? name,
    int? orderIndex,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'name': name,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int?,
      gameId: map['game_id'] as int,
      name: map['name'] as String,
      orderIndex: map['order_index'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, gameId: $gameId, name: $name, orderIndex: $orderIndex)';
  }
}

class PlayerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // プレイヤーを作成
  Future<Player> createPlayer(Player player) async {
    final db = await _dbHelper.database;
    
    final id = await db.insert(
      'players',
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return player.copyWith(id: id);
  }

  // 複数のプレイヤーを一括作成
  Future<List<Player>> createPlayers(List<Player> players) async {
    final db = await _dbHelper.database;
    final List<Player> createdPlayers = [];
    
    await db.transaction((txn) async {
      for (final player in players) {
        final id = await txn.insert(
          'players',
          player.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        createdPlayers.add(player.copyWith(id: id));
      }
    });
    
    return createdPlayers;
  }

  // ゲームIDでプレイヤーを取得
  Future<List<Player>> getPlayersByGameId(int gameId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'players',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'order_index ASC',
    );
    
    return List.generate(maps.length, (i) => Player.fromMap(maps[i]));
  }

  // プレイヤーを更新
  Future<int> updatePlayer(Player player) async {
    final db = await _dbHelper.database;
    
    return await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  // プレイヤーを削除
  Future<int> deletePlayer(int id) async {
    final db = await _dbHelper.database;
    
    return await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ゲームIDでプレイヤーを削除
  Future<int> deletePlayersByGameId(int gameId) async {
    final db = await _dbHelper.database;
    
    return await db.delete(
      'players',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
  }
}

// Riverpod Provider
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository();
});

final playersByGameProvider = FutureProvider.family<List<Player>, int>((ref, gameId) async {
  final repository = ref.read(playerRepositoryProvider);
  return await repository.getPlayersByGameId(gameId);
}); 