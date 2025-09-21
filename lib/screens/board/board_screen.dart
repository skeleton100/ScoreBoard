import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_color.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../routes/route_names.dart';
import 'round_list_tab.dart';
import 'summary_tab.dart';

final _tabIndexProvider = StateProvider<int>((ref) => 0);

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentGame = ref.watch(currentGameProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        title: Text(currentGame?.title ?? 'Scoreboard'),
        backgroundColor: AppColors.boardAppBar,
        foregroundColor: AppColors.textLight,
        leading: IconButton(
          onPressed: () => context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: const TabBar(
          labelStyle: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(color: AppColors.textLight),
          indicatorColor: AppColors.textLight,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: '各スコア'),
            Tab(text: 'サマリ'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 設定画面に遷移
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: TabBarView(
        children: [
          RoundListTab(),
          SummaryTab(),
        ],
      ),
      ),
    );
  }

  Widget _buildNoGameSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_soccer,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'ゲームが選択されていません',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '新しいゲームを作成してください',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(RouteNames.gameConfig),
            icon: const Icon(Icons.add),
            label: const Text('新しいゲームを作成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'エラーが発生しました',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? '不明なエラー',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, Game game, List<Player> players) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ゲーム情報
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ウマ: ${game.uma.displayText}', 
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (game.memo != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'メモ: ${game.memo}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // プレイヤー一覧
          Text(
            'プレイヤー (${players.length}人)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...players.map((player) => Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  '${player.orderIndex + 1}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                player.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'プレイヤー${player.orderIndex + 1}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )).toList(),

          const SizedBox(height: 24),

          // スコア入力ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.scoreInput),
              icon: const Icon(Icons.add),
              label: const Text('スコアを入力'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
