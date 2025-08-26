# BL-005: 統計機能

## 概要
プレイヤーとゲームの詳細な統計情報を表示する機能を実装する。

## 背景
ゲーム記録が蓄積された後、プレイヤーの成績や傾向を分析できる統計機能が必要。長期的な成績向上やゲームの振り返りに役立つ情報を提供する。

## 要件

### 機能要件
1. **プレイヤー統計**
   - 総ゲーム数・勝率
   - 平均順位・平均得点
   - 最高得点・最低得点
   - 和了率・放銃率
   - 月別・期間別成績

2. **ゲーム統計**
   - ゲームごとの詳細記録
   - 局数分布・平均局数
   - 得点分布
   - 特殊な局の記録

3. **比較機能**
   - プレイヤー間の成績比較
   - 期間別成績の推移
   - ランキング表示

4. **可視化**
   - グラフ・チャート表示
   - 成績の推移グラフ
   - レーダーチャート
   - ヒートマップ

### 非機能要件
- 大量データの効率的な処理
- グラフの高速描画
- フィルタリング・ソート機能

## 技術設計

### データベース設計
```sql
-- 統計用ビューの作成
CREATE VIEW player_statistics AS
SELECT 
    p.id as player_id,
    p.name,
    COUNT(gr.id) as total_games,
    AVG(gr.rank) as avg_rank,
    AVG(gr.final_score) as avg_score,
    SUM(CASE WHEN gr.rank = 1 THEN 1 ELSE 0 END) as wins,
    MAX(gr.final_score) as max_score,
    MIN(gr.final_score) as min_score
FROM players p
LEFT JOIN game_results gr ON p.id = gr.player_id
GROUP BY p.id, p.name;
```

### 統計計算クラス
```dart
class StatisticsCalculator {
  static PlayerStatistics calculatePlayerStats(int playerId, {
    DateRange? period,
    List<int>? gameIds,
  });
  
  static GameStatistics calculateGameStats(int gameId);
  
  static List<PlayerComparison> compareplayers(List<int> playerIds);
  
  static TimeSeriesData getPlayerProgression(int playerId);
}

class PlayerStatistics {
  final int totalGames;
  final double avgRank;
  final double avgScore;
  final int wins;
  final double winRate;
  final Map<int, int> rankDistribution;
  final List<ScoreDistribution> scoreHistory;
}
```

### UI設計
1. **統計画面（StatisticsScreen）**
   - タブ切り替え（全体・プレイヤー別・ゲーム別）
   - 期間フィルター
   - グラフ表示エリア

2. **プレイヤー詳細統計（PlayerStatsScreen）**
   - 個人成績サマリー
   - 成績推移グラフ
   - 詳細データテーブル

3. **比較画面（ComparisonScreen）**
   - 複数プレイヤー選択
   - 比較チャート
   - ランキング表示

## グラフ・チャート

### 使用ライブラリ
- `fl_chart` - Flutter用チャートライブラリ
- カスタムウィジェットによる独自実装

### チャート種類
1. **線グラフ**: 成績推移
2. **棒グラフ**: 順位分布、得点分布
3. **レーダーチャート**: プレイヤー能力
4. **ヒートマップ**: 月別成績
5. **円グラフ**: 順位割合

## 統計指標

### 基本指標
- 総ゲーム数
- 勝率（1位率）
- 平均順位
- 平均得点
- 最高/最低得点

### 詳細指標
- トップ率・ラス率
- 飛び率・飛ばし率
- 平均局数
- 連続トップ記録
- 月別成績

### 高度な指標
- 安定性指数（順位のばらつき）
- 攻撃力指数（高得点の頻度）
- 守備力指数（失点の少なさ）

## 画面遷移
```
統計画面
├── プレイヤー統計
│   ├── 個人詳細統計
│   └── プレイヤー比較
├── ゲーム統計
│   └── ゲーム詳細統計
└── 全体統計
    └── ランキング
```

## 受け入れ条件
- [ ] プレイヤーの基本統計が表示される
- [ ] 成績推移をグラフで確認できる
- [ ] 複数プレイヤーの成績を比較できる
- [ ] 期間を指定して統計を取得できる
- [ ] 統計データをソート・フィルタリングできる
- [ ] グラフが適切に描画される
- [ ] 大量データでもパフォーマンスが維持される
- [ ] エクスポート機能が動作する

## 依存関係
- **前提条件**: BL-002（得点計算機能）、BL-003（半荘記録機能）
- **後続タスク**: BL-007（データエクスポート）

## 見積もり
- **ストーリーポイント**: 8
- **作業時間**: 2-3日
- **難易度**: 中

## 補足
- 初期実装では基本的な統計のみ
- グラフライブラリの学習が必要
- 将来的にはAI分析機能も検討
- パフォーマンス最適化は継続的に実施