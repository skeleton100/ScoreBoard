import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_color.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../providers/round_provider.dart';

// プレイヤーごとの累積スコアと順位を管理するクラス
class PlayerSummary {
  final int playerIndex;
  final String playerName;
  final int totalScore;
  final int rank;

  const PlayerSummary({
    required this.playerIndex,
    required this.playerName,
    required this.totalScore,
    required this.rank,
  });
}

// 累積スコアを計算するプロバイダー
final playerSummariesProvider = Provider.autoDispose<List<PlayerSummary>>((ref) {
  final currentGame = ref.watch(currentGameProvider);
  if (currentGame == null) return [];

  final playersAsync = ref.watch(currentGamePlayersProvider);
  final rounds = ref.watch(gameRoundsProvider(currentGame.id.toString()));

  // プレイヤー情報が読み込まれていない場合は空リストを返す
  return playersAsync.when(
    data: (players) {
      if (players.isEmpty) return [];

      // 各プレイヤーの累積スコアを計算
      final totalScores = List<int>.filled(players.length, 0);

      for (final round in rounds) {
        // プレイヤー割り当て情報を使ってスコアを集計
        // round.playerAssignments: { windIndex: playerIndex }
        // round.scores: 各風のスコア（東南西北の順）
        round.playerAssignments.forEach((windIndex, playerIndex) {
          if (windIndex < round.scores.length && playerIndex < totalScores.length) {
            totalScores[playerIndex] += round.scores[windIndex];
          }
        });
      }

      // PlayerSummaryリストを作成
      final summaries = players.asMap().entries.map((entry) {
        return PlayerSummary(
          playerIndex: entry.key,
          playerName: entry.value.name,
          totalScore: totalScores[entry.key],
          rank: 0, // 仮の順位
        );
      }).toList();

      // スコアでソート（高い順）
      summaries.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      // 順位を付与
      final rankedSummaries = <PlayerSummary>[];
      for (int i = 0; i < summaries.length; i++) {
        rankedSummaries.add(PlayerSummary(
          playerIndex: summaries[i].playerIndex,
          playerName: summaries[i].playerName,
          totalScore: summaries[i].totalScore,
          rank: i + 1,
        ));
      }

      return rankedSummaries;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class SummaryTab extends ConsumerWidget {
  const SummaryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentGame = ref.watch(currentGameProvider);

    if (currentGame == null) {
      return const Center(
        child: Text(
          'ゲームが選択されていません',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final playerSummaries = ref.watch(playerSummariesProvider);
    final rounds = ref.watch(gameRoundsProvider(currentGame.id.toString()));

    if (rounds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'まだラウンドがありません',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ラウンドを追加すると集計結果が表示されます',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ゲーム情報カード
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ゲーム情報',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'タイトル', value: currentGame.title),
                  _InfoRow(label: 'ウマ', value: currentGame.uma.displayText),
                  _InfoRow(label: 'オカ', value: currentGame.oka.displayText),
                  _InfoRow(label: 'ラウンド数', value: '${rounds.length}局'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 順位表
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最終順位',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...playerSummaries.map((summary) {
                    return _RankingItem(summary: summary);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final PlayerSummary summary;

  const _RankingItem({
    required this.summary,
  });

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events; // Trophy
      case 2:
        return Icons.military_tech; // Medal
      case 3:
        return Icons.military_tech; // Medal
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: summary.rank == 1
            ? const Color(0xFFFFF9E6)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: summary.rank <= 3
              ? _getRankColor(summary.rank).withValues(alpha: 0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // 順位アイコン
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getRankColor(summary.rank).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getRankIcon(summary.rank),
                color: _getRankColor(summary.rank),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // プレイヤー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${summary.rank}位',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getRankColor(summary.rank),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      summary.playerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'プレイヤー${summary.playerIndex + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // スコア
          Text(
            '${summary.totalScore >= 0 ? '+' : ''}${summary.totalScore}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: summary.totalScore >= 0
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}