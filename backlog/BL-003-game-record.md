# BL-003: 半荘記録機能

## 概要
半荘（東風戦・東南戦）の完全な記録管理機能を実装する。

## 背景
BL-001（スコア入力）とBL-004（スコアボード表示）により局ごとの記録は可能だが、半荘全体の管理と記録機能が不足している。ゲームの開始から終了までの完全な流れを管理する。

## 要件

### 機能要件
1. **半荘進行管理**
   - 東風戦/東南戦の選択
   - 局の自動進行（東1局→東2局→...）
   - 連荘・流局の処理
   - 終了条件の判定

2. **局履歴表示**
   - 過去の局の結果一覧
   - 局ごとの詳細情報
   - 得点変動グラフ
   - 局の編集・削除機能

3. **ゲーム状態管理**
   - 進行中/一時停止/終了の状態
   - オーラス（最終局）の判定
   - トビ（マイナス点）の処理
   - 途中終了機能

4. **記録の永続化**
   - 半荘の詳細記録保存
   - 中断・再開機能
   - 記録の検索・フィルタリング

### 非機能要件
- データの整合性保証
- 大量データの効率的な処理
- 直感的な操作性

## 技術設計

### データベース設計拡張
```sql
-- gamesテーブルの拡張
ALTER TABLE games ADD COLUMN game_type TEXT DEFAULT 'tonnan'; -- 'tonpuu' or 'tonnan'
ALTER TABLE games ADD COLUMN current_round INTEGER DEFAULT 1;
ALTER TABLE games ADD COLUMN current_honba INTEGER DEFAULT 0;
ALTER TABLE games ADD COLUMN game_status TEXT DEFAULT 'playing'; -- 'playing', 'paused', 'finished'

-- 局の詳細情報拡張
ALTER TABLE rounds ADD COLUMN is_renchan BOOLEAN DEFAULT 0;
ALTER TABLE rounds ADD COLUMN is_ryukyoku BOOLEAN DEFAULT 0;
ALTER TABLE rounds ADD COLUMN tenpai_players TEXT; -- JSON形式でテンパイプレイヤーを記録
```

### 新しいモデル
```dart
enum GameType { tonpuu, tonnan }
enum GameStatus { playing, paused, finished }
enum RoundResult { win, ryukyoku }

class GameSession {
  final Game game;
  final List<Player> players;
  final List<Round> rounds;
  final GameType gameType;
  final GameStatus status;
  final int currentRound;
  final int currentHonba;
  
  bool get isFinished => /* 終了判定ロジック */;
  bool get isOoras => /* オーラス判定 */;
}
```

### UI設計
1. **ゲーム進行画面の拡張**
   - 現在局の詳細表示
   - 次局への進行ボタン
   - ゲーム一時停止機能

2. **局履歴画面（RoundHistoryScreen）**
   - 局一覧のタイムライン表示
   - 各局の詳細ビュー
   - 得点変動チャート

3. **ゲーム設定画面の拡張**
   - 東風戦/東南戦の選択
   - 終了条件の設定

## ゲーム進行ロジック

### 局の進行
1. 現在局の入力完了
2. 次局の判定（連荘・流局の処理）
3. 終了条件のチェック
4. 次局の準備 or ゲーム終了

### 終了条件
- **通常終了**: 規定局数の完了
- **途中終了**: マイナス点によるトビ
- **延長**: オーラスでのトップ条件
- **手動終了**: ユーザーによる強制終了

### 連荘の処理
```dart
class RoundProgresser {
  static Round getNextRound(Round currentRound, RoundResult result) {
    if (result == RoundResult.win && currentRound.winner_id == currentRound.oya_id) {
      // 連荘
      return currentRound.copyWith(honba: currentRound.honba + 1);
    } else {
      // 次局
      return Round(
        round_number: _getNextRoundNumber(currentRound.round_number),
        honba: 0,
        // ...
      );
    }
  }
}
```

## 画面遷移図
```
BoardScreen（スコアボード）
├── ScoreInputScreen（スコア入力）
│   └── 局入力完了 → 次局判定 → BoardScreen更新
├── RoundHistoryScreen（局履歴）
│   ├── 局詳細ビュー
│   └── 局編集機能
└── GameResultScreen（最終結果）
    └── ゲーム終了処理
```

## 受け入れ条件
- [ ] 東風戦/東南戦を選択してゲームを開始できる
- [ ] 局が正しい順序で進行する
- [ ] 連荘・流局の処理が正しく動作する
- [ ] 局履歴を一覧表示できる
- [ ] 過去の局の詳細を確認できる
- [ ] 得点変動を視覚的に確認できる
- [ ] ゲームの一時停止・再開ができる
- [ ] 正しい終了条件でゲームが終了する
- [ ] トビの処理が正しく動作する
- [ ] オーラスの処理が正しく動作する

## 依存関係
- **前提条件**: BL-001（スコア入力機能）、BL-004（スコアボード表示）
- **後続タスク**: BL-005（統計機能）、BL-006（履歴機能）

## 見積もり
- **ストーリーポイント**: 13
- **作業時間**: 3-4日
- **難易度**: 高

## 補足
- 麻雀ルールの詳細な理解が必要
- ゲーム状態の複雑な管理が必要
- 将来的には三麻対応も検討
- リアルタイム対戦機能は別エピックで対応