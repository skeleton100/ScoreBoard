import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game.dart';
import '../../services/point_calc_service.dart';
import '../../models/umaoka.dart';
import '../../models/input_mode.dart';
import '../../models/same_point_mode.dart';
import '../../models/wind.dart';

// スコア入力の状態を管理するクラス
class ScoreInputState {
  final InputMode inputMode;
  final List<String> inputValues;
  final bool isCalculated;
  final List<int>? calculationResult;
  final String? errorMessage;
  final Map<Wind, int?> playerAssignments; // 風→プレイヤーインデックスのマッピング

  const ScoreInputState({
    required this.inputMode,
    required this.inputValues,
    required this.isCalculated,
    this.calculationResult,
    this.errorMessage,
    required this.playerAssignments,
  });

  ScoreInputState copyWith({
    InputMode? inputMode,
    List<String>? inputValues,
    bool? isCalculated,
    List<int>? calculationResult,
    String? errorMessage,
    Map<Wind, int?>? playerAssignments,
  }) {
    return ScoreInputState(
      inputMode: inputMode ?? this.inputMode,
      inputValues: inputValues ?? this.inputValues,
      isCalculated: isCalculated ?? this.isCalculated,
      calculationResult: calculationResult ?? this.calculationResult,
      errorMessage: errorMessage,
      playerAssignments: playerAssignments ?? this.playerAssignments,
    );
  }
}

// バリデーション結果を表すクラス
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  static const ValidationResult valid = ValidationResult(isValid: true);
  
  static ValidationResult invalid(String message) {
    return ValidationResult(isValid: false, errorMessage: message);
  }
}

// 計算結果を表すクラス
class CalculationResult {
  final bool isSuccess;
  final List<int>? scores;
  final String? errorMessage;

  const CalculationResult({
    required this.isSuccess,
    this.scores,
    this.errorMessage,
  });

  static CalculationResult success(List<int> scores) {
    return CalculationResult(isSuccess: true, scores: scores);
  }

  static CalculationResult error(String message) {
    return CalculationResult(isSuccess: false, errorMessage: message);
  }
}

// スコア入力のビジネスロジックを管理するクラス
class ScoreInputNotifier extends StateNotifier<ScoreInputState> {
  ScoreInputNotifier() : super(ScoreInputState(
    inputMode: InputMode.tenbo,
    inputValues: const ['', '', '', ''],
    isCalculated: false,
    playerAssignments: {
      Wind.east: 0,
      Wind.south: 1,
      Wind.west: 2,
      Wind.north: 3,
    },
  ));

  // 入力モードを変更
  void changeInputMode(InputMode newMode) {
    state = state.copyWith(
      inputMode: newMode,
      inputValues: ['', '', '', ''],
      isCalculated: false,
      calculationResult: null,
      errorMessage: null,
    );
  }

  // プレイヤー割り当てを変更
  void assignPlayer(Wind wind, int? playerIndex) {
    final newAssignments = Map<Wind, int?>.from(state.playerAssignments);
    newAssignments[wind] = playerIndex;

    state = state.copyWith(
      playerAssignments: newAssignments,
      isCalculated: false,
      calculationResult: null,
      errorMessage: null,
    );
  }

  // 特定のプレイヤーの入力値を更新
  void updatePlayerInput(int playerIndex, String value) {
    final newInputValues = List<String>.from(state.inputValues);
    newInputValues[playerIndex] = value;
    
    state = state.copyWith(
      inputValues: newInputValues,
      isCalculated: false,
      calculationResult: null,
      errorMessage: null,
    );
  }

  // 全ての入力値をクリア
  void clearAllInputs() {
    state = state.copyWith(
      inputValues: ['', '', '', ''],
      isCalculated: false,
      calculationResult: null,
      errorMessage: null,
    );
  }

  // 単一フィールドのバリデーション
  ValidationResult validateSingleInput(String? value, InputMode mode) {
    if (value == null || value.isEmpty) {
      return ValidationResult.invalid('値を入力してください');
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      return ValidationResult.invalid('数字を入力してください');
    }

    if (mode == InputMode.tenbo) {
      // 点棒モード: ハコテンを考慮して負の値も許可
      // 上限は999（99900点）、下限は制限なし
      if (intValue > 999) {
        return ValidationResult.invalid('999以下の値を入力してください');
      }
    }

    return ValidationResult.valid;
  }

  // 全ての入力値のバリデーション
  ValidationResult validateAllInputs() {
    final inputValues = state.inputValues;
    final playerAssignments = state.playerAssignments;

    // プレイヤー割り当ての重複チェック
    final assignedPlayerIndices = playerAssignments.values.whereType<int>().toList();
    final uniqueIndices = assignedPlayerIndices.toSet();
    if (assignedPlayerIndices.length != uniqueIndices.length) {
      return ValidationResult.invalid('同じプレイヤーが複数の風に割り当てられています');
    }

    // 全てのプレイヤーが割り当てられているかチェック
    if (playerAssignments.values.any((index) => index == null)) {
      return ValidationResult.invalid('全ての風にプレイヤーを割り当ててください');
    }

    // 空の値がないかチェック
    for (int i = 0; i < inputValues.length; i++) {
      final validation = validateSingleInput(inputValues[i], state.inputMode);
      if (!validation.isValid) {
        return ValidationResult.invalid('プレイヤー${i + 1}: ${validation.errorMessage}');
      }
    }

    final values = inputValues.map((v) => int.parse(v)).toList();

    if (state.inputMode == InputMode.tenbo) {
      // 点棒モード: 合計が100,000点（=1000）になるかチェック
      final total = values.reduce((a, b) => a + b);
      const expectedTotal = 1000; // 100,000点 ÷ 100

      // 負の値がある場合（ハコテン）はチェックをスキップ
      final hasNegative = values.any((v) => v < 0);

      if (!hasNegative && total != expectedTotal) {
        final actualPoints = total * 100;
        return ValidationResult.invalid('点棒の合計が100,000点になりません。\n現在の合計: $actualPoints点');
      }
    } else {
      // 点数モード: 合計が0になるかチェック
      final totalScore = values.reduce((a, b) => a + b);
      if (totalScore != 0) {
        return ValidationResult.invalid('点数の合計が0になりません。\n現在の合計: $totalScore点');
      }
    }

    return ValidationResult.valid;
  }

  // 計算を実行
  CalculationResult calculate(Game? currentGame) {
    final validation = validateAllInputs();
    if (!validation.isValid) {
      return CalculationResult.error(validation.errorMessage!);
    }

    final values = state.inputValues.map((v) => int.parse(v)).toList();

    if (state.inputMode == InputMode.tenbo) {
      return _calculateFromPoints(values, currentGame);
    } else {
      return _calculateFromScores(values);
    }
  }

  // 点棒モードの計算（ウマ・オカを含む）
  CalculationResult _calculateFromPoints(List<int> values, Game? currentGame) {
    try {

      // PointCalcServiceを使用してウマオカ計算を実行
      final pointCalcService = PointCalcService();
      final uma = Uma.uma5_10; // デフォルトで5-10を使用
      final oka = Oka.oka25;    // デフォルトで25000点持ちを使用
      final samePointMode = SamePointMode.kamicha; // デフォルトで上家取りを使用

      final result = pointCalcService.calculateTenbo(values, uma, oka, samePointMode);
      return CalculationResult.success(result);

    } catch (e) {
      return CalculationResult.error('計算エラー: ${e.toString()}');
    }
  }

  // 点数モードの計算（単純にそのまま返す）
  CalculationResult _calculateFromScores(List<int> values) {
    return CalculationResult.success(values);
  }


  // 計算を実行して状態を更新
  void performCalculation(Game? currentGame) {
    final result = calculate(currentGame);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isCalculated: true,
        calculationResult: result.scores,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        isCalculated: false,
        calculationResult: null,
        errorMessage: result.errorMessage,
      );
    }
  }

  // 計算結果をリセット
  void resetCalculation() {
    state = state.copyWith(
      isCalculated: false,
      calculationResult: null,
      errorMessage: null,
    );
  }
}

// Riverpod プロバイダー（autoDispose: 画面破棄時に自動的に状態をリセット）
final scoreInputProvider = StateNotifierProvider.autoDispose<ScoreInputNotifier, ScoreInputState>((ref) {
  return ScoreInputNotifier();
});

// 個別の状態にアクセスするためのプロバイダー（UI用）
final inputModeProvider = Provider.autoDispose<InputMode>((ref) {
  return ref.watch(scoreInputProvider).inputMode;
});

final isCalculatedProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(scoreInputProvider).isCalculated;
});

final calculationResultProvider = Provider.autoDispose<List<int>?>((ref) {
  return ref.watch(scoreInputProvider).calculationResult;
});

final errorMessageProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(scoreInputProvider).errorMessage;
});

// プレイヤー割り当て（風→プレイヤーインデックス）を取得するプロバイダー
final playerAssignmentsProvider = Provider.autoDispose<Map<Wind, int?>>((ref) {
  return ref.watch(scoreInputProvider).playerAssignments;
});

// 特定のプレイヤーの入力値を取得するプロバイダー
final playerInputProvider = Provider.autoDispose.family<String, int>((ref, playerIndex) {
  return ref.watch(scoreInputProvider).inputValues[playerIndex];
});

// 入力値の合計を計算するプロバイダー
// 1つでも入力があれば合計を表示
final inputSumProvider = Provider.autoDispose<int?>((ref) {
  final state = ref.watch(scoreInputProvider);
  final inputValues = state.inputValues;

  // 入力された値のみを解析
  final parsedValues = <int>[];
  for (final value in inputValues) {
    if (value.isEmpty) continue;

    final parsed = int.tryParse(value);
    if (parsed == null) {
      return null;
    }
    parsedValues.add(parsed);
  }

  // 何も入力されていない場合はnullを返す
  if (parsedValues.isEmpty) {
    return null;
  }

  // 点棒モードの場合は100倍して合計
  if (state.inputMode == InputMode.tenbo) {
    return parsedValues.map((v) => v * 100).reduce((a, b) => a + b);
  } else {
    // 点数モードの場合はそのまま合計
    return parsedValues.reduce((a, b) => a + b);
  }
});