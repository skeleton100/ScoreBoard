# BL-002: 得点計算機能

## 概要
麻雀のウマオカを考慮した最終得点計算機能を実装する。

## 背景
BL-001で局ごとのスコア入力が可能になった後、ゲーム終了時に最終的な順位と精算金額を計算する機能が必要。

## 要件

### 機能要件
1. **順位計算**
   - 最終持ち点による順位決定
   - 同点時の処理（起家優先など）

2. **ウマオカ計算**
   - 設定されたウマオカに基づく精算
   - 基準点からの差分計算
   - ウマ（順位点）の加算

3. **計算結果表示**
   - 各プレイヤーの最終持ち点
   - 順位
   - 精算金額（プラス/マイナス）
   - 計算過程の表示

4. **ゲーム終了処理**
   - 計算結果の確定
   - ゲーム状態の更新（終了フラグ）

### 非機能要件
- 計算の正確性
- 計算過程の透明性
- エラーハンドリング

## 技術設計

### 計算ロジック
```dart
class ScoreCalculator {
  static ScoreResult calculateFinalScores(
    List<Player> players,
    Map<String, int> finalScores,
    int basePoint,
    double umaOka,
  ) {
    // 1. 順位決定
    // 2. ウマオカ計算
    // 3. 精算金額計算
  }
}
```

### データベース拡張
```sql
-- gamesテーブルに終了状態を追加
ALTER TABLE games ADD COLUMN is_finished BOOLEAN DEFAULT 0;
ALTER TABLE games ADD COLUMN finished_at TEXT;

-- 最終結果テーブル
CREATE TABLE game_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  game_id INTEGER NOT NULL,
  player_id INTEGER NOT NULL,
  final_score INTEGER NOT NULL,
  rank INTEGER NOT NULL,
  uma_oka_result INTEGER NOT NULL, -- 精算金額
  created_at TEXT NOT NULL,
  FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
  FOREIGN KEY (player_id) REFERENCES players(id)
);
```

### UI設計
1. **計算結果画面（GameResultScreen）**
   - プレイヤー別結果表示
   - 順位テーブル
   - 精算金額一覧
   - 計算詳細（折りたたみ式）

2. **計算確認ダイアログ**
   - 計算結果のプレビュー
   - 確定前の最終確認

### ルーティング
- `/game-result/:gameId` - 計算結果画面
- BoardScreenから遷移

## ウマオカ計算仕様

### 基本計算式
```
精算金額 = (最終得点 - 基準点) / 1000 + ウマ

ウマ計算：
- 1位: +ウマオカ点
- 2位: +ウマオカ点/2
- 3位: -ウマオカ点/2  
- 4位: -ウマオカ点点
```

### 例（基準点25000、ウマオカ10の場合）
- プレイヤーA: 32000点 → (32000-25000)/1000 + 10 = +17
- プレイヤーB: 28000点 → (28000-25000)/1000 + 5 = +8
- プレイヤーC: 24000点 → (24000-25000)/1000 - 5 = -6
- プレイヤーD: 16000点 → (16000-25000)/1000 - 10 = -19

## 受け入れ条件
- [ ] 最終持ち点から正確な順位を計算できる
- [ ] ウマオカを考慮した精算金額を計算できる
- [ ] 計算結果が視覚的に分かりやすく表示される
- [ ] 計算過程を確認できる
- [ ] ゲームの終了状態をデータベースに記録できる
- [ ] 精算がプラスマイナスゼロになることを確認できる
- [ ] 同点時の処理が正しく動作する

## 依存関係
- **前提条件**: BL-001（スコア入力機能）
- **後続タスク**: BL-005（統計機能）、BL-006（履歴機能）

## 見積もり
- **ストーリーポイント**: 5
- **作業時間**: 1-2日
- **難易度**: 中

## 補足
- 将来的には複数のウマオカルールに対応予定
- トビ（マイナス点）の処理も後の機能で対応
- 計算結果のSNS共有機能は別タスク（BL-015）で対応