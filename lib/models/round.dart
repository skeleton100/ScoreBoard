import 'package:uuid/uuid.dart';

class Round {
  final String id;
  final String gameId;
  final String roundName; // 東1局、東2局など
  final List<int> scores; // 各プレイヤーのスコア
  final DateTime createdAt;
  final DateTime updatedAt;

  Round({
    String? id,
    required this.gameId,
    required this.roundName,
    required this.scores,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Round copyWith({
    String? id,
    String? gameId,
    String? roundName,
    List<int>? scores,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Round(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      roundName: roundName ?? this.roundName,
      scores: scores ?? List.from(this.scores),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'roundName': roundName,
      'scores': scores,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      id: json['id'],
      gameId: json['gameId'],
      roundName: json['roundName'],
      scores: List<int>.from(json['scores']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Round && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Round{id: $id, gameId: $gameId, roundName: $roundName, scores: $scores}';
  }
}