import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_color.dart';
import '../../models/game.dart';
import '../../models/round.dart';
import '../../providers/round_provider.dart';
import '../../routes/route_names.dart';

class RoundListTab extends ConsumerWidget {
  const RoundListTab({super.key});

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

    final gameRounds = ref.watch(gameRoundsProvider(currentGame.id.toString()));

    return Column(
      children: [
        // 上部の+ボタン
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => context.go(RouteNames.scoreInput),
            icon: const Icon(Icons.add),
            label: const Text('新しいラウンドを追加'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        // ラウンドリスト
        Expanded(
          child: gameRounds.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
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
                        '「新しいラウンドを追加」ボタンを\n押してラウンドを作成してください',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: gameRounds.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemBuilder: (context, index) {
                    final round = gameRounds[index];
                    return _RoundListItem(
                      round: round,
                      onTap: () {
                        // TODO: 編集モードでscore_input_screenに遷移
                        context.go(RouteNames.scoreInput);
                      },
                      onDelete: () => _showDeleteDialog(context, ref, round),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Round round) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ラウンドを削除'),
        content: Text('「${round.roundName}」を削除してもよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(roundsProvider.notifier).deleteRound(round.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('「${round.roundName}」を削除しました'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

class _RoundListItem extends StatelessWidget {
  final Round round;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RoundListItem({
    required this.round,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // スコアの合計を計算
    final totalScore = round.scores.reduce((a, b) => a + b);
    
    // 最高スコアを取得
    final maxScore = round.scores.reduce((a, b) => a > b ? a : b);
    final winnerIndex = round.scores.indexWhere((score) => score == maxScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            round.roundName.substring(0, 2), // 東1、南2 etc.
            style: const TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          round.roundName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'プレイヤー${winnerIndex + 1}が1位 (${maxScore >= 0 ? '+' : ''}${maxScore}点)',
              style: TextStyle(
                color: maxScore >= 0 ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatDate(round.createdAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '合計: ${totalScore >= 0 ? '+' : ''}$totalScore',
              style: TextStyle(
                color: totalScore == 0 
                    ? AppColors.textSecondary 
                    : totalScore > 0 
                        ? AppColors.success 
                        : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              tooltip: '削除',
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (itemDate == today) {
      return '今日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (itemDate == yesterday) {
      return '昨日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}