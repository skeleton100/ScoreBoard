import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/score_text_field.dart';
import '../../utils/app_color.dart';
import '../../models/game.dart';
import '../../models/round.dart';
import '../../providers/round_provider.dart';
import 'score_input_model.dart';
import '../../models/input_mode.dart';

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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
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
      final roundName = ref.read(roundsProvider.notifier).generateRoundName(currentGame.id.toString());
      
      // ラウンドを作成
      final round = Round(
        gameId: currentGame.id.toString(),
        roundName: roundName,
        scores: calculationResult,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                              title: const Text('点棒'),
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
                              title: const Text('点数'),
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
                      Text(
                        inputMode == InputMode.tenbo ? '点棒入力' : '点数入力',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(4, (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ScoreTextField(
                          label: 'プレイヤー${index + 1}',
                          controller: _controllers[index],
                          isPointMode: inputMode == InputMode.tenbo,
                          validator: (value) => _validateInput(value, inputMode),
                          onChanged: (value) => _onFieldChanged(value, index),
                        ),
                      )),
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
                              Text('プレイヤー${index + 1}:'),
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