import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/umaoka.dart';

class GameConfigModel {
  final String title;
  final List<String> playerNames;
  final Uma uma;
  final Oka oka;
  final int basePoint;
  final String? memo;
  final DateTime createdAt;

  GameConfigModel({
    required this.title,
    required this.playerNames,
    required this.uma,
    required this.oka,
    required this.basePoint,
    this.memo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GameConfigModel copyWith({
    String? title,
    List<String>? playerNames,
    Uma? uma,
    Oka? oka,
    int? basePoint,
    String? memo,
    DateTime? createdAt,
  }) {
    return GameConfigModel(
      title: title ?? this.title,
      playerNames: playerNames ?? this.playerNames,
      uma: uma ?? this.uma,
      oka: oka ?? this.oka,
      basePoint: basePoint ?? this.basePoint,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'playerNames': playerNames,
      'uma': uma,
      'oka': oka,
      'basePoint': basePoint,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GameConfigModel.fromJson(Map<String, dynamic> json) {
    return GameConfigModel(
      title: json['title'] as String,
      playerNames: List<String>.from(json['playerNames']),
      uma: (json['uma'] as Uma?) ?? Uma.uma5_10, // デフォルト値を設定
      oka: (json['oka'] as Oka?) ?? Oka.oka25, // デフォルト値を設定
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
        other.uma == uma &&
        other.oka == oka &&
        other.basePoint == basePoint &&
        other.memo == memo;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        playerNames.hashCode ^
        uma.hashCode ^
        oka.hashCode ^
        basePoint.hashCode ^
        memo.hashCode;
  }

  @override
  String toString() {
    return 'GameConfigModel(title: $title, playerNames: $playerNames, uma: $uma, oka: $oka, basePoint: $basePoint, memo: $memo)';
  }
}

// Riverpod Provider for GameConfigModel
class GameConfigNotifier extends StateNotifier<GameConfigModel?> {
  GameConfigNotifier() : super(null);

  void initializeConfig() {
    state = GameConfigModel(
      title: '',
      playerNames: ['', '', '', ''],
      uma: Uma.uma5_10,
      oka: Oka.oka25,
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

  void updateUma(double uma) {
    if (state != null) {
      state = state!.copyWith(uma: uma as Uma);
    }
  }

  void updateOka(double oka) {
    if (state != null) {
      state = state!.copyWith(oka: oka as Oka);
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

final umaProvider = StateProvider<Uma?>((ref) => Uma.uma5_10);
final okaProvider = StateProvider<Oka?>((ref) => Oka.oka25);