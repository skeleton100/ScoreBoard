import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game.dart';
import '../../services/point_calc_service.dart';
import '../../models/umaoka.dart';
import '../../models/input_mode.dart';

// スコア入力の状態を管理するクラス
class ScoreInputState {
  final InputMode inputMode;
  final List<String> inputValues;
  final bool isCalculated;
  final List<int>? calculationResult;
  final String? errorMessage;

  const ScoreInputState({
    required this.inputMode,
    required this.inputValues,
    required this.isCalculated,
    this.calculationResult,
    this.errorMessage,
  });

  ScoreInputState copyWith({
    InputMode? inputMode,
    List<String>? inputValues,
    bool? isCalculated,
    List<int>? calculationResult,
    String? errorMessage,
  }) {
    return ScoreInputState(
      inputMode: inputMode ?? this.inputMode,
      inputValues: inputValues ?? this.inputValues,
      isCalculated: isCalculated ?? this.isCalculated,
      calculationResult: calculationResult ?? this.calculationResult,
      errorMessage: errorMessage,
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
  ScoreInputNotifier() : super(const ScoreInputState(
    inputMode: InputMode.tenbo,
    inputValues: ['', '', '', ''],
    isCalculated: false,
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
    
    if (mode == InputMode.tenbo) {
      final intValue = int.tryParse(value);
      if (intValue == null) {
        return ValidationResult.invalid('数字を入力してください');
      }
      if (intValue < 0 || intValue > 999) {
        return ValidationResult.invalid('0-999の範囲で入力してください');
      }
    } else {
      final intValue = int.tryParse(value);
      if (intValue == null) {
        return ValidationResult.invalid('数字を入力してください（負数可）');
      }
    }
    return ValidationResult.valid;
  }

  // 全ての入力値のバリデーション
  ValidationResult validateAllInputs() {
    final inputValues = state.inputValues;
    
    // 空の値がないかチェック
    for (int i = 0; i < inputValues.length; i++) {
      final validation = validateSingleInput(inputValues[i], state.inputMode);
      if (!validation.isValid) {
        return ValidationResult.invalid('プレイヤー${i + 1}: ${validation.errorMessage}');
      }
    }

    final values = inputValues.map((v) => int.parse(v)).toList();

    if (state.inputMode == InputMode.tenbo) {
      // 点棒モード: 合計が100,000点になるかチェック
      final actualPoints = values.map((v) => v * 100).toList();
      final totalPoints = actualPoints.reduce((a, b) => a + b);
      if (totalPoints != 100000) {
        return ValidationResult.invalid('点棒の合計が100,000点になりません。\\n現在の合計: ${totalPoints}点');
      }
    } else {
      // 点数モード: 合計が0になるかチェック
      final totalScore = values.reduce((a, b) => a + b);
      if (totalScore != 0) {
        return ValidationResult.invalid('点数の合計が0になりません。\\n現在の合計: ${totalScore}点');
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
      final actualPoints = values.map((v) => v * 100).toList();

      // PointCalcServiceを使用してウマオカ計算を実行
      final pointCalcService = PointCalcService();
      final uma = Uma.uma10_20; // デフォルトで10-20を使用
      final oka = Oka.oka25;    // デフォルトで25000点持ちを使用

      final result = pointCalcService.calculateTenbo(actualPoints, uma, oka);
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

// Riverpod プロバイダー
final scoreInputProvider = StateNotifierProvider<ScoreInputNotifier, ScoreInputState>((ref) {
  return ScoreInputNotifier();
});

// 個別の状態にアクセスするためのプロバイダー（UI用）
final inputModeProvider = Provider<InputMode>((ref) {
  return ref.watch(scoreInputProvider).inputMode;
});

final isCalculatedProvider = Provider<bool>((ref) {
  return ref.watch(scoreInputProvider).isCalculated;
});

final calculationResultProvider = Provider<List<int>?>((ref) {
  return ref.watch(scoreInputProvider).calculationResult;
});

final errorMessageProvider = Provider<String?>((ref) {
  return ref.watch(scoreInputProvider).errorMessage;
});

// 特定のプレイヤーの入力値を取得するプロバイダー
final playerInputProvider = Provider.family<String, int>((ref, playerIndex) {
  return ref.watch(scoreInputProvider).inputValues[playerIndex];
});