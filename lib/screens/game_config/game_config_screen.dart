import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_color.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../routes/route_names.dart';
import 'game_config_model.dart';
import '../../models/umaoka.dart';
import '../../widgets/common_dropdown.dart';

class GameConfigScreen extends ConsumerStatefulWidget {
  const GameConfigScreen({super.key});

  @override
  ConsumerState<GameConfigScreen> createState() => _GameConfigScreenState();
}

class _GameConfigScreenState extends ConsumerState<GameConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isMemoVisible = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // 画面が初期化されたときに設定を初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameConfigProvider.notifier).initializeConfig();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    ref.read(gameConfigProvider.notifier).addPlayer();
  }

  void _removePlayer(int index) {
    ref.read(gameConfigProvider.notifier).removePlayer(index);
  }

  Future<void> _createGameConfig() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

      try {
        final notifier = ref.read(gameConfigProvider.notifier);
        
        // メモが表示されている場合はメモを更新
        if (_isMemoVisible) {
          notifier.updateMemo(_memoController.text.isEmpty ? null : _memoController.text);
        }

        if (notifier.isValid()) {
          final gameConfig = ref.read(gameConfigProvider);
          if (gameConfig == null) {
            throw Exception('ゲーム設定が無効です');
          }

          // Gameモデルを作成
          final game = Game(
            title: gameConfig.title,
            uma: gameConfig.uma,
            oka: gameConfig.oka,
            roundRule: gameConfig.roundRule,
            memo: gameConfig.memo,
          );

          // データベースに保存
          final gameRepository = ref.read(gameRepositoryProvider);
          final createdGame = await gameRepository.createGame(game);

          // プレイヤーを作成
          final playerRepository = ref.read(playerRepositoryProvider);
          final players = gameConfig.playerNames.asMap().entries.map((entry) {
            return Player(
              gameId: createdGame.id!,
              name: entry.value,
              orderIndex: entry.key,
            );
          }).toList();

          await playerRepository.createPlayers(players);

          // 現在のゲームを設定
          ref.read(currentGameProvider.notifier).state = createdGame;

          // ゲーム一覧を更新（ホーム画面で新しいゲームが表示されるように）
          ref.invalidate(gamesProvider);

          // 設定をリセット
          notifier.reset();

          // 成功メッセージを表示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('記録表を作成しました'),
                backgroundColor: AppColors.success,
              ),
            );
          }

          // board_screenに遷移
          if (mounted) {
            context.go(RouteNames.board);
          }
        } else {
          throw Exception('必要な情報を入力してください');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラーが発生しました: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameConfig = ref.watch(gameConfigProvider);

    if (gameConfig == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('麻雀記録表作成'),
        backgroundColor: AppColors.gameConfigAppBar,
        foregroundColor: AppColors.textLight,
        leading: IconButton(
          onPressed: () => context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: _isCreating ? null : _createGameConfig,
        //     child: _isCreating
        //         ? const SizedBox(
        //             width: 20,
        //             height: 20,
        //             child: CircularProgressIndicator(
        //               strokeWidth: 2,
        //               valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
        //             ),
        //           )
        //         : const Text(
        //             '作成',
        //             style: TextStyle(color: AppColors.textLight, fontSize: 16),
        //           ),
        //   ),
        // ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // タイトル入力
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'タイトル',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: '例: 2024年1月麻雀会',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          ref.read(gameConfigProvider.notifier).updateTitle(value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'タイトルを入力してください';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // プレイヤー名入力
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'プレイヤー名',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: _addPlayer,
                            icon: const Icon(Icons.add, color: AppColors.secondary),
                            tooltip: 'プレイヤーを追加',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(gameConfig.playerNames.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'プレイヤー${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    ref.read(gameConfigProvider.notifier).updatePlayerName(index, value);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'プレイヤー名を入力してください';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (gameConfig.playerNames.length > 4)
                                IconButton(
                                  onPressed: () => _removePlayer(index),
                                  icon: const Icon(Icons.remove, color: AppColors.error),
                                  tooltip: 'プレイヤーを削除',
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ウマオカ設定
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ウマ設定',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CommonDropdown(
                        items: Uma.values,
                        provider: umaProvider,
                        labelBuilder: (uma) => uma.displayText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 基準点設定
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'オカ設定',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CommonDropdown(
                        items: Oka.values,
                        provider: okaProvider,
                        labelBuilder: (oka) => oka.displayText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // メモ入力（オプション）
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'メモ（オプション）',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isMemoVisible,
                            onChanged: (value) {
                              setState(() {
                                _isMemoVisible = value;
                              });
                            },
                            activeColor: AppColors.secondary,
                          ),
                        ],
                      ),
                      if (_isMemoVisible) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _memoController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'メモを入力してください',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            ref.read(gameConfigProvider.notifier).updateMemo(
                              value.isEmpty ? null : value,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_isCreating ? null : () => _createGameConfig()),
        child: const Icon(Icons.save),
      ),
    );
  }
}
