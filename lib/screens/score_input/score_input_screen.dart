import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../widgets/score_text_field.dart';
import '../../utils/app_color.dart';
import '../../models/game.dart';
import '../../models/round.dart';
import '../../providers/round_provider.dart';

enum InputMode { points, scores }

final inputModeProvider = StateProvider<InputMode>((ref) => InputMode.points);
final calculatedProvider = StateProvider<bool>((ref) => false);
final calculationResultProvider = StateProvider<List<int>?>((ref) => null);

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
    ref.read(calculatedProvider.notifier).state = false;
    ref.read(calculationResultProvider.notifier).state = null;
  }

  void _onFieldChanged(String value) {
    ref.read(calculatedProvider.notifier).state = false;
    ref.read(calculationResultProvider.notifier).state = null;
  }

  String? _validateInput(String? value, InputMode mode) {
    if (value == null || value.isEmpty) {
      return '値を入力してください';
    }
    
    if (mode == InputMode.points) {
      final intValue = int.tryParse(value);
      if (intValue == null) {
        return '数字を入力してください';
      }
      if (intValue < 0 || intValue > 999) {
        return '0-999の範囲で入力してください';
      }
    } else {
      final intValue = int.tryParse(value);
      if (intValue == null) {
        return '数字を入力してください（負数可）';
      }
    }
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final inputMode = ref.read(inputModeProvider);
    final values = _controllers.map((c) => int.parse(c.text)).toList();

    if (inputMode == InputMode.points) {
      // 点棒モード: 点棒を点数に変換
      final actualPoints = values.map((v) => v * 100).toList();
      final totalPoints = actualPoints.reduce((a, b) => a + b);
      if (totalPoints != 100000) {
        _showErrorDialog('点棒の合計が100,000点になりません。\n現在の合計: ${totalPoints}点');
        return;
      }

      final basePoint = ref.read(currentGameProvider)?.basePoint ?? 30000; // 基準点からの差分を計算
      final sortedScores = List.from(actualPoints)..sort((a, b) => b.compareTo(a)); // 4位から計算するため降順ソート

      var forthScore = (_roundOff(sortedScores[0]) - basePoint)/1000;//五捨六入して4位の基準点からの差分を計算
      var thirdScore = (_roundOff(sortedScores[1]) - basePoint)/1000;//五捨六入して3位の基準点からの差分を計算
      var secondScore = (_roundOff(sortedScores[2]) - basePoint)/1000;//五捨六入して2位の基準点からの差分を計算
      var firstScore = (_roundOff(sortedScores[3]) - basePoint)/1000;//五捨六入して1位の基準点からの差分を計算

      final uma = ref.read(currentGameProvider)?.uma ?? 10.0;
      final oka = ref.read(currentGameProvider)?.oka ?? 20.0;
      final scores = [firstScore + uma + oka, secondScore + uma / 2, thirdScore - uma / 2, forthScore - uma];
      
      // TODO(human): ウマ・オカ計算を実装
      // 1. 各プレイヤーの素点（点棒-basePoint）を計算
      // 2. 順位を判定（降順ソート）
      // 3. ウマ・オカを適用して最終スコアを計算
      // final scores = actualPoints.map((v) => v - 25000).toList();
      ref.read(calculationResultProvider.notifier).state = scores.map((v) => v.toInt()).toList();
    } else {
      // 点数モード: 合計が0かチェック
      final totalScore = values.reduce((a, b) => a + b);
      if (totalScore != 0) {
        _showErrorDialog('点数の合計が0になりません。\n現在の合計: ${totalScore}点');
        return;
      }
      
      ref.read(calculationResultProvider.notifier).state = values;
    }
    
    ref.read(calculatedProvider.notifier).state = true;
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
      ref.read(calculatedProvider.notifier).state = false;
      ref.read(calculationResultProvider.notifier).state = null;
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

  int _roundOff(int score) {
    int roundDigit = (score ~/ pow(10, 3 - 1)) % 10;
    if (roundDigit >= 6) {
      return score + 1000;
    } else {
      return score;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputMode = ref.watch(inputModeProvider);
    final isCalculated = ref.watch(calculatedProvider);
    final calculationResult = ref.watch(calculationResultProvider);
    final currentGame = ref.watch(currentGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('スコア入力'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        leading: IconButton(
          onPressed: () => context.pop(),
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
                        Text('基準点: ${currentGame.basePoint}点'),
                        Text('ウマ: ${currentGame.uma.toInt()}点'),
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
                              value: InputMode.points,
                              groupValue: inputMode,
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(inputModeProvider.notifier).state = value;
                                  _onInputModeChanged();
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<InputMode>(
                              title: const Text('点数'),
                              value: InputMode.scores,
                              groupValue: inputMode,
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(inputModeProvider.notifier).state = value;
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
                        inputMode == InputMode.points ? '点棒入力' : '点数入力',
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
                          isPointMode: inputMode == InputMode.points,
                          validator: (value) => _validateInput(value, inputMode),
                          onChanged: _onFieldChanged,
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