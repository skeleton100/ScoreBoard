import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameConfigModel {
  final String title;
  final List<String> playerNames;
  final double umaOka;
  final int basePoint;
  final String? memo;
  final DateTime createdAt;

  GameConfigModel({
    required this.title,
    required this.playerNames,
    required this.umaOka,
    required this.basePoint,
    this.memo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GameConfigModel copyWith({
    String? title,
    List<String>? playerNames,
    double? umaOka,
    int? basePoint,
    String? memo,
    DateTime? createdAt,
  }) {
    return GameConfigModel(
      title: title ?? this.title,
      playerNames: playerNames ?? this.playerNames,
      umaOka: umaOka ?? this.umaOka,
      basePoint: basePoint ?? this.basePoint,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'playerNames': playerNames,
      'umaOka': umaOka,
      'basePoint': basePoint,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GameConfigModel.fromJson(Map<String, dynamic> json) {
    return GameConfigModel(
      title: json['title'] as String,
      playerNames: List<String>.from(json['playerNames']),
      umaOka: json['umaOka'] as double,
      basePoint: json['basePoint'] as int,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameConfigModel &&
        other.title == title &&
        other.playerNames.length == playerNames.length &&
        other.umaOka == umaOka &&
        other.basePoint == basePoint &&
        other.memo == memo;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        playerNames.hashCode ^
        umaOka.hashCode ^
        basePoint.hashCode ^
        memo.hashCode;
  }

  @override
  String toString() {
    return 'GameConfigModel(title: $title, playerNames: $playerNames, umaOka: $umaOka, basePoint: $basePoint, memo: $memo)';
  }
}

// Riverpod Provider for GameConfigModel
class GameConfigNotifier extends StateNotifier<GameConfigModel?> {
  GameConfigNotifier() : super(null);

  void initializeConfig() {
    state = GameConfigModel(
      title: '',
      playerNames: ['', '', '', ''],
      umaOka: 10.0,
      basePoint: 25000,
      memo: null,
    );
  }

  void updateTitle(String title) {
    if (state != null) {
      state = state!.copyWith(title: title);
    }
  }

  void updatePlayerName(int index, String name) {
    if (state != null) {
      final newPlayerNames = List<String>.from(state!.playerNames);
      if (index < newPlayerNames.length) {
        newPlayerNames[index] = name;
        state = state!.copyWith(playerNames: newPlayerNames);
      }
    }
  }

  void addPlayer() {
    if (state != null) {
      final newPlayerNames = List<String>.from(state!.playerNames);
      newPlayerNames.add('');
      state = state!.copyWith(playerNames: newPlayerNames);
    }
  }

  void removePlayer(int index) {
    if (state != null && state!.playerNames.length > 4) {
      final newPlayerNames = List<String>.from(state!.playerNames);
      newPlayerNames.removeAt(index);
      state = state!.copyWith(playerNames: newPlayerNames);
    }
  }

  void updateUmaOka(double umaOka) {
    if (state != null) {
      state = state!.copyWith(umaOka: umaOka);
    }
  }

  void updateBasePoint(int basePoint) {
    if (state != null) {
      state = state!.copyWith(basePoint: basePoint);
    }
  }

  void updateMemo(String? memo) {
    if (state != null) {
      state = state!.copyWith(memo: memo);
    }
  }

  void reset() {
    state = null;
  }

  bool isValid() {
    if (state == null) return false;
    
    return state!.title.isNotEmpty &&
           state!.playerNames.every((name) => name.isNotEmpty) &&
           state!.playerNames.length >= 4;
  }
}

final gameConfigProvider = StateNotifierProvider<GameConfigNotifier, GameConfigModel?>((ref) {
  return GameConfigNotifier();
}); 