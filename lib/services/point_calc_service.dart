import 'package:collection/collection.dart';
import '../../models/umaoka.dart';
import '../../models/rank_data.dart';

class PointCalcService {

  
  List<int> calculateTenbo(List<int> values, Uma uma, Oka oka) {
    if (values.length == 4) {
      // 正しい麻雀計算: (点棒 - 30000) / 1000
      final scores = values.map((value) => (_roundOff(value) - 30000) ~/ 1000).toList();
      final sortedUniqueScores = scores.sorted((a, b) => b.compareTo(a)).toSet().toList();

      RankData calcUmaOka(RankData rankData) {
        // 基本的なウマの適用
        int umaBonus = 0;
        switch (rankData.rank) {
          case 1:
            umaBonus = uma.uma2; // 1位は上位ウマ
            break;
          case 2:
            umaBonus = uma.uma1; // 2位は下位ウマ
            break;
          case 3:
            umaBonus = -uma.uma1; // 3位は下位ウマのマイナス
            break;
          case 4:
            umaBonus = -uma.uma2; // 4位は上位ウマのマイナス
            break;
        }

        // オカの適用（25000点持ちの場合の調整）
        int okaBonus = 0;
        if (rankData.rank == 1) {
          okaBonus = oka.oka; // 1位にのみオカを適用
        }

        return rankData.copyWith(
          score: rankData.score + umaBonus + okaBonus,
          rank: rankData.rank
        );
      }

      if (!_hasDuplicate(scores)) {
        final List<RankData> rankedScores = scores.map(
          (score) =>
          RankData(score: score,
                   rank: sortedUniqueScores.indexOf(score) + 1)
        ).toList();

        final List<RankData> calculatedScores = rankedScores.map(calcUmaOka).toList();
        return calculatedScores.map((rankData) => rankData.score!).toList();
      } else {
        // 重複がある場合の処理：平均順位を使用
        final List<RankData> rankedScores = [];

        for (int i = 0; i < scores.length; i++) {
          final score = scores[i];
          final sameScoreCount = scores.where((s) => s == score).length;

          if (sameScoreCount == 1) {
            // 重複なし
            rankedScores.add(RankData(
              score: score,
              rank: sortedUniqueScores.indexOf(score) + 1,
            ));
          } else {
            // 重複あり：平均順位を計算
            final baseRank = sortedUniqueScores.indexOf(score) + 1;
            final averageRank = baseRank + (sameScoreCount - 1) / 2.0;
            rankedScores.add(RankData(
              score: score,
              rank: averageRank.round(),
            ));
          }
        }

        final List<RankData> calculatedScores = rankedScores.map(calcUmaOka).toList();
        return calculatedScores.map((rankData) => rankData.score!).toList();
      }
    }
    else {
      throw Exception('Values length must be 4');
    }
  }

  // 点棒の上位3桁を受け取って五捨六入処理
  static int _roundOff(int score) {
    int lastDigit = score % 10;
    if (lastDigit >= 6) {
      return score + 10 - lastDigit; // ex. 256(00) -> 260(00)
    } else {
      return score - lastDigit; // ex. 254(00) -> 250(00)
    }
  } 

  static bool _hasDuplicate(List<int> scores) {
    return scores.toSet().length != scores.length;
  }
}