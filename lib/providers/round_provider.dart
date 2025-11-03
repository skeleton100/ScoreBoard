import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/round.dart';
import '../models/game.dart';
import '../models/round_rule.dart';

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

  // ラウンド番号を自動生成（RoundRuleに応じて）
  String generateRoundName(String gameId, RoundRule roundRule) {
    final gameRounds = state.where((round) => round.gameId == gameId).toList();
    final roundCount = gameRounds.length + 1;

    switch (roundRule) {
      case RoundRule.quarter: // 東風戦
        if (roundCount <= 4) {
          return '${roundRule.displayText}$roundCount';
        } else {
          return '${roundRule.displayText}$roundCount'; // 延長戦も東風として継続
        }
      case RoundRule.half: // 半荘戦
        if (roundCount <= 4) {
          return '${roundRule.displayText}$roundCount';
        } else if (roundCount <= 8) {
          return '${roundRule.displayText}$roundCount';
        } else {
          return '${roundRule.displayText}$roundCount'; // 延長戦
        }
      case RoundRule.full: // 一荘戦
        if (roundCount <= 4) {
          return '東$roundCount局';
        } else if (roundCount <= 8) {
          return '南${roundCount - 4}局';
        } else if (roundCount <= 12) {
          return '西${roundCount - 8}局';
        } else if (roundCount <= 16) {
          return '北${roundCount - 12}局';
        } else {
          return '${roundRule.displayText}$roundCount'; // 延長戦
        }
    }
  }
}