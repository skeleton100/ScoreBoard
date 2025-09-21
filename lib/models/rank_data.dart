class RankData {
  final int score;
  final int rank;

  RankData({
    required this.score,
    required this.rank,
  });

  @override
  String toString() {
    return 'Score: $score, Rank: $rank';
  }

  RankData copyWith({
    int? score,
    int? rank,
  }) {
    return RankData(score: score ?? this.score, rank: rank ?? this.rank);
  }
}

