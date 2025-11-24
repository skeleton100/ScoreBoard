import 'package:collection/collection.dart';
import '../../models/umaoka.dart';
import '../../models/rank_data.dart';
import '../../utils/app_constants.dart';
import '../../models/same_point_mode.dart';

class PointCalcService {


  List<int> calculateTenbo(List<int> values, Uma uma, Oka oka, SamePointMode mode) {
    // 4人以外の場合は単純に素点を計算（ウマ・オカなし）
    if (values.length != 4) {
      return values.map((value) => (_roundOff(value) - AppConstants.basePoint) ~/ 10).toList();
    }

    if (values.length == 4) {
      // 正しい麻雀計算: (点棒 - 30000) / 1000
      final scores = values.map((value) => (_roundOff(value) - AppConstants.basePoint) ~/ 10).toList();
      final sortedScores = scores.sorted((a, b) => b.compareTo(a)).toList();

      RankData calcUmaOka(RankData rankData) {
        // 基本的なウマの適用
        int umaBonus = 0;
        switch (rankData.rank) {
          case 1:
            umaBonus = uma.upperUma; // 1位は上位ウマ
            break;
          case 2:
            umaBonus = uma.lowerUma; // 2位は下位ウマ
            break;
          case 3:
            umaBonus = -uma.lowerUma; // 3位は下位ウマのマイナス
            break;
          case 4:
            umaBonus = -uma.upperUma; // 4位は上位ウマのマイナス
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
                   rank: sortedScores.indexOf(score) + 1)
        ).toList();

        final List<RankData> calculatedScores = rankedScores.map(calcUmaOka).toList();
        return calculatedScores.map((rankData) => rankData.score).toList();
      } else {
        // 重複がある場合の処理：SamePointModeに応じて処理を分ける
        switch (mode) {
          case SamePointMode.kamicha:
            return _calculateWithKamicha(scores, calcUmaOka);
          case SamePointMode.split:
            return _calculateWithSplit(scores, calcUmaOka, uma, oka);
        }
      }
    }

    // この行には到達しないはず
    throw Exception('Unexpected error in calculateTenbo');
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

  // 上家取りロジックの実装
  // 同点の場合、起家に近い（indexが小さい）プレイヤーが上位になる
  List<int> _calculateWithKamicha(List<int> scores, RankData Function(RankData) calcUmaOka) {
    // 点数とインデックスをペアにする
    List<({int score, int index})> scoreWithIndex = [];
    for (int i = 0; i < scores.length; i++) {
      scoreWithIndex.add((score: scores[i], index: i));
    }

    // 点数でソート（高い順）。同点の場合はindexが小さい方を上位に
    scoreWithIndex.sort((a, b) {
      int scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      // 同点の場合はインデックスが小さい方（起家に近い方）が上位
      return a.index.compareTo(b.index);
    });

    // 順位を決定してウマ・オカを適用
    List<RankData> results = List.filled(scores.length, RankData(score: 0, rank: 0));

    for (int i = 0; i < scoreWithIndex.length; i++) {
      int playerIndex = scoreWithIndex[i].index;
      int rank = i + 1;
      RankData rankData = RankData(score: scores[playerIndex], rank: rank);
      results[playerIndex] = calcUmaOka(rankData);
    }

    return results.map((rankData) => rankData.score).toList();
  }

  // 折半ロジック（同点時は該当順位のウマを平均化）
  List<int> _calculateWithSplit(List<int> scores, RankData Function(RankData) calcUmaOka, Uma uma, Oka oka) {
    // 点数とインデックスをペアにする
    List<({int score, int index})> scoreWithIndex = [];
    for (int i = 0; i < scores.length; i++) {
      scoreWithIndex.add((score: scores[i], index: i));
    }

    // 点数でソート（高い順）
    scoreWithIndex.sort((a, b) => b.score.compareTo(a.score));

    // 順位を決定（同点グループを特定）
    List<List<int>> rankGroups = [];
    List<int> currentGroup = [0];

    for (int i = 1; i < scoreWithIndex.length; i++) {
      if (scoreWithIndex[i].score == scoreWithIndex[i-1].score) {
        currentGroup.add(i);
      } else {
        rankGroups.add([...currentGroup]);
        currentGroup = [i];
      }
    }
    rankGroups.add(currentGroup);

    // 各グループに順位を割り当て、ウマを計算
    List<RankData> results = List.filled(scores.length, RankData(score: 0, rank: 0));
    int currentRank = 1;

    for (List<int> group in rankGroups) {
      if (group.length == 1) {
        // 同点でない場合は通常の計算
        int playerIndex = scoreWithIndex[group[0]].index;
        RankData rankData = RankData(score: scores[playerIndex], rank: currentRank);
        results[playerIndex] = calcUmaOka(rankData);
      } else {
        // 同点の場合は該当順位のウマを平均化
        List<int> rankRange = List.generate(group.length, (i) => currentRank + i);
        double avgUma = _calculateAverageUma(rankRange, uma);

        for (int groupIndex in group) {
          int playerIndex = scoreWithIndex[groupIndex].index;
          int baseScore = scores[playerIndex];

          // オカは1位のみ適用
          int okaBonus = (currentRank == 1) ? oka.oka : 0;

          results[playerIndex] = RankData(
            score: baseScore + avgUma.round() + okaBonus,
            rank: currentRank
          );
        }
      }
      currentRank += group.length;
    }

    return results.map((rankData) => rankData.score).toList();
  }

  // 該当順位のウマの平均を計算
  double _calculateAverageUma(List<int> ranks, Uma uma) {
    double totalUma = 0;
    for (int rank in ranks) {
      switch (rank) {
        case 1:
          totalUma += uma.upperUma;
          break;
        case 2:
          totalUma += uma.lowerUma;
          break;
        case 3:
          totalUma -= uma.lowerUma;
          break;
        case 4:
          totalUma -= uma.upperUma;
          break;
      }
    }
    return totalUma / ranks.length;
  }
}