import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_color.dart';
import '../../models/game.dart';
import '../../models/round.dart';
import '../../providers/round_provider.dart';
import 'score_input_model.dart';
import '../../models/input_mode.dart';
import '../../models/wind.dart';
import '../../models/round_rule.dart';
import '../../models/player.dart';

class ScoreInputScreen extends ConsumerStatefulWidget {
  const ScoreInputScreen({super.key});

  @override
  ConsumerState<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends ConsumerState<ScoreInputScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isAutoFilling = false; // 自動入力中フラグ

  @override
  void initState() {
    super.initState();
    // フォーカスノードにリスナーを追加
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        // フォーカスが外れた時に自動入力をチェック
        if (!_focusNodes[i].hasFocus && !_isAutoFilling) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryAutoFill();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onInputModeChanged() {
    // モード変更時にフィールドをクリア
    for (var controller in _controllers) {
      controller.clear();
    }
    ref.read(scoreInputProvider.notifier).clearAllInputs();
  }

  void _onFieldChanged(String value, int playerIndex) {
    ref.read(scoreInputProvider.notifier).updatePlayerInput(playerIndex, value);
  }

  void _tryAutoFill() {
    if (_isAutoFilling) return; // 既に自動入力中の場合は何もしない

    final inputMode = ref.read(inputModeProvider);
    final inputValues = ref.read(scoreInputProvider).inputValues;

    print('=== _tryAutoFill called ===');
    print('inputValues: $inputValues');

    // 空のフィールドを探す
    int? emptyIndex;
    int filledCount = 0;

    for (int i = 0; i < inputValues.length; i++) {
      if (inputValues[i].isEmpty) {
        if (emptyIndex != null) {
          // 空のフィールドが2つ以上ある場合は自動入力しない
          print('複数の空フィールドがあるため自動入力しない');
          return;
        }
        emptyIndex = i;
      } else {
        filledCount++;
      }
    }

    print('emptyIndex: $emptyIndex, filledCount: $filledCount');

    // 正確に3つのフィールドが埋まっており、1つだけ空の場合
    if (emptyIndex != null && filledCount == 3) {
      // 入力された3つの値を取得
      final values = <int>[];
      for (int i = 0; i < inputValues.length; i++) {
        if (i == emptyIndex) continue;

        final parsed = int.tryParse(inputValues[i]);
        if (parsed == null) {
          print('パースエラー: inputValues[$i] = ${inputValues[i]}');
          return; // パースエラーがある場合は自動入力しない
        }
        values.add(parsed);
      }

      print('parsed values: $values');

      if (values.length != 3) {
        print('values.length != 3');
        return;
      }

      // 目標値を計算
      final int targetSum = inputMode == InputMode.tenbo ? 1000 : 0;

      // 現在の合計を計算
      final currentSum = values.reduce((a, b) => a + b);

      // 差分を計算
      final autoValue = targetSum - currentSum;

      print('targetSum: $targetSum, currentSum: $currentSum, autoValue: $autoValue');

      // 自動入力フラグを立てる
      _isAutoFilling = true;

      // Controllerとstateを更新
      _controllers[emptyIndex].text = autoValue.toString();
      ref.read(scoreInputProvider.notifier).updatePlayerInput(emptyIndex, autoValue.toString());

      print('自動入力完了: index=$emptyIndex, value=$autoValue');

      // 自動入力フラグを下ろす
      _isAutoFilling = false;
    }
  }

  String? _validateInput(String? value, InputMode mode) {
    final validation = ref.read(scoreInputProvider.notifier).validateSingleInput(value, mode);
    return validation.isValid ? null : validation.errorMessage;
  }

  // TODO(human): Replace this method with model-based calculation
  // Use ref.read(scoreInputProvider.notifier).performCalculation(currentGame)
  // Handle error messages from the model's errorMessageProvider
  void _calculate() {
    final currentGame = ref.read(currentGameProvider);
    ref.read(scoreInputProvider.notifier).performCalculation(currentGame);
    
    // Check for errors and show dialog if needed
    final errorMessage = ref.read(errorMessageProvider);
    if (errorMessage != null) {
      _showErrorDialog(errorMessage.replaceAll('\\\\n', '\n'));
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('入力エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onOkPressed() async {
    final currentGame = ref.read(currentGameProvider);
    final calculationResult = ref.read(calculationResultProvider);
    
    if (currentGame == null || calculationResult == null) {
      return;
    }

    try {
      // ラウンド名を生成
      final roundName = ref.read(roundsProvider.notifier).generateRoundName(currentGame.id.toString(), currentGame.roundRule);

      // プレイヤー割り当てを取得（Wind → プレイヤーindex）
      final playerAssignments = ref.read(playerAssignmentsProvider);

      // Wind → プレイヤーindex のマップを windIndex → playerIndex に変換
      final assignmentsMap = <int, int>{};
      playerAssignments.forEach((wind, playerIndex) {
        if (playerIndex != null) {
          assignmentsMap[wind.index] = playerIndex;
        }
      });

      // ラウンドを作成
      final round = Round(
        gameId: currentGame.id.toString(),
        roundName: roundName,
        scores: calculationResult,
        playerAssignments: assignmentsMap,
      );

      // ラウンドを保存
      ref.read(roundsProvider.notifier).addRound(round);
      
      // 状態をリセット
      ref.read(scoreInputProvider.notifier).clearAllInputs();
      for (var controller in _controllers) {
        controller.clear();
      }
      
      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「$roundName」のスコアが保存されました'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Board画面のround_list_tabに戻る
        context.go('/board');
      }
    } catch (e) {
      // エラーメッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 五捨六入処理はモデルに移行済み

  @override
  Widget build(BuildContext context) {
    final inputMode = ref.watch(inputModeProvider);
    final isCalculated = ref.watch(isCalculatedProvider);
    final calculationResult = ref.watch(calculationResultProvider);
    final currentGame = ref.watch(currentGameProvider);
    final inputSum = ref.watch(inputSumProvider);
    final playersAsync = ref.watch(currentGamePlayersProvider);
    final playerAssignments = ref.watch(playerAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('スコア入力'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/board');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ゲーム情報表示
              if (currentGame != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentGame.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('ウマ: ${currentGame.uma.displayText}'),
                        Text('オカ: ${currentGame.oka.displayText}'),
                        Text('ルール: ${currentGame.roundRule.displayText}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ルール選択
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ルール設定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: RoundRule.values.map((rule) {
                          return RadioListTile<RoundRule>(
                            title: Text(rule.displayText),
                            value: rule,
                            groupValue: currentGame?.roundRule,
                            onChanged: (value) {
                              if (value != null && currentGame != null) {
                                final updatedGame = currentGame.copyWith(roundRule: value);
                                ref.read(currentGameProvider.notifier).state = updatedGame;
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 入力モード選択
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '入力モード',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<InputMode>(
                              title: Text(InputMode.tenbo.displayText),
                              value: InputMode.tenbo,
                              groupValue: inputMode,
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(scoreInputProvider.notifier).changeInputMode(value);
                                  _onInputModeChanged();
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<InputMode>(
                              title: Text(InputMode.score.displayText),
                              value: InputMode.score,
                              groupValue: inputMode,
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(scoreInputProvider.notifier).changeInputMode(value);
                                  _onInputModeChanged();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // プレイヤー入力フィールド
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inputMode == InputMode.tenbo ? '点棒入力' : '点数入力',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (inputSum != null)
                            Text(
                              inputMode == InputMode.tenbo
                                ? '合計: $inputSum点'
                                : '合計: ${inputSum >= 0 ? '+' : ''}$inputSum点',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: inputSum == (inputMode == InputMode.tenbo ? 100000 : 0)
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      playersAsync.when(
                        data: (players) {
                          return Column(
                            children: Wind.values.map((wind) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 風のラベル
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Text(
                                        wind.displayText,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // プレイヤー選択と点数入力を横並び
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // プレイヤー選択ドロップダウン
                                        Expanded(
                                          flex: 2,
                                          child: DropdownButtonFormField<int>(
                                            value: playerAssignments[wind],
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            ),
                                            items: players.asMap().entries.map((entry) {
                                              return DropdownMenuItem<int>(
                                                value: entry.key,
                                                child: Text(entry.value.name),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              ref.read(scoreInputProvider.notifier).assignPlayer(wind, value);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // 点数入力フィールド（点棒モード時は00点を表示）
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _controllers[wind.index],
                                                  focusNode: _focusNodes[wind.index],
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    labelText: inputMode == InputMode.tenbo ? '点棒' : '点数',
                                                    border: const OutlineInputBorder(),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                  ),
                                                  validator: (value) => _validateInput(value, inputMode),
                                                  onChanged: (value) => _onFieldChanged(value, wind.index),
                                                ),
                                              ),
                                              if (inputMode == InputMode.tenbo)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4.0),
                                                  child: Text(
                                                    '00点',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Column(
                          children: Wind.values.map((wind) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      wind.displayText,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _controllers[wind.index],
                                          focusNode: _focusNodes[wind.index],
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: inputMode == InputMode.tenbo ? '点棒' : '点数',
                                            border: const OutlineInputBorder(),
                                          ),
                                          validator: (value) => _validateInput(value, inputMode),
                                          onChanged: (value) => _onFieldChanged(value, wind.index),
                                        ),
                                      ),
                                      if (inputMode == InputMode.tenbo)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: Text(
                                            '00点',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 計算結果表示
              if (isCalculated && calculationResult != null) ...[
                Card(
                  color: AppColors.success.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '計算結果',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(4, (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${Wind.values[index].displayText}:'),
                              Text(
                                '${calculationResult[index] >= 0 ? '+' : ''}${calculationResult[index]}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: calculationResult[index] >= 0
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ボタン
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('計算'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isCalculated ? _onOkPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}