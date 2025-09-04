import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/round.dart';
import '../models/game.dart';

// ラウンドリストの状態管理
final roundsProvider = StateNotifierProvider<RoundNotifier, List<Round>>((ref) {
  return RoundNotifier();
});

// 特定のゲームのラウンドを取得
final gameRoundsProvider = Provider.family<List<Round>, String>((ref, gameId) {
  final rounds = ref.watch(roundsProvider);
  return rounds.where((round) => round.gameId == gameId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 新しい順
});

class RoundNotifier extends StateNotifier<List<Round>> {
  RoundNotifier() : super([]);

  // ラウンドを追加
  void addRound(Round round) {
    state = [...state, round];
  }

  // ラウンドを更新
  void updateRound(Round updatedRound) {
    state = state.map((round) {
      return round.id == updatedRound.id ? updatedRound : round;
    }).toList();
  }

  // ラウンドを削除
  void deleteRound(String roundId) {
    state = state.where((round) => round.id != roundId).toList();
  }

  // 特定のゲームのラウンドを全削除
  void deleteGameRounds(String gameId) {
    state = state.where((round) => round.gameId != gameId).toList();
  }

  // IDでラウンドを取得
  Round? getRoundById(String roundId) {
    try {
      return state.firstWhere((round) => round.id == roundId);
    } catch (e) {
      return null;
    }
  }

  // ラウンド番号を自動生成
  String generateRoundName(String gameId) {
    final gameRounds = state.where((round) => round.gameId == gameId).toList();
    final roundCount = gameRounds.length + 1;
    
    // 簡単なラウンド名生成ロジック（東風戦想定）
    if (roundCount <= 4) {
      return '東${roundCount}局';
    } else if (roundCount <= 8) {
      return '南${roundCount - 4}局';
    } else {
      return '第${roundCount}局';
    }
  }
}