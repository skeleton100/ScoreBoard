# BL-001: スコア入力機能

## 概要
麻雀の局ごとのスコア（点数）を入力する機能を実装する。

## 背景
現在、ゲームとプレイヤーの登録は完了しているが、実際の局の結果を記録する機能がない。麻雀アプリの核となる得点入力機能を実装する必要がある。

## 要件

### 機能要件
1. **局情報入力**
   - 局数（東1局、南2局など）
   - 本場（本場数）
   - リーチ棒の数

2. **得点入力**
   - 各プレイヤーの持ち点変動
   - ツモ/ロンの区別
   - 和了者の選択
   - 役の記録（オプション）

3. **入力バリデーション**
   - 得点の合計が0になることを確認
   - 負の持ち点にならないよう警告表示
   - 必須項目のチェック

4. **データ保存**
   - 局の結果をデータベースに保存
   - 累計得点の更新

### 非機能要件
- レスポンシブデザイン（タブレット対応）
- 直感的な操作性
- エラーハンドリング

## 技術設計

### データベース設計
新しいテーブルの追加:
```sql
CREATE TABLE rounds (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  game_id INTEGER NOT NULL,
  round_number INTEGER NOT NULL, -- 局数（1=東1、5=南1）
  honba INTEGER DEFAULT 0,
  riichi_sticks INTEGER DEFAULT 0,
  winner_id INTEGER, -- NULL=流局
  winner_type TEXT, -- 'tsumo' or 'ron'
  created_at TEXT NOT NULL,
  FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
  FOREIGN KEY (winner_id) REFERENCES players(id)
);

CREATE TABLE round_scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  round_id INTEGER NOT NULL,
  player_id INTEGER NOT NULL,
  score_change INTEGER NOT NULL,
  total_score INTEGER NOT NULL,
  FOREIGN KEY (round_id) REFERENCES rounds(id) ON DELETE CASCADE,
  FOREIGN KEY (player_id) REFERENCES players(id)
);
```

### 新しいモデル
- `Round`: 局の情報を管理
- `RoundScore`: 局ごとのプレイヤースコア変動
- `RoundRepository`: データベースアクセス

### UI設計
1. **スコア入力画面（ScoreInputScreen）**
   - 現在の局情報表示エリア
   - プレイヤーごとのスコア入力フィールド
   - 和了情報入力エリア
   - 確定ボタン

2. **入力方式の選択**
   - 得点変動入力（+1000、-500など）
   - 現在点入力（25000、24000など）

### ルーティング
- `/score-input/:gameId` - スコア入力画面
- BoardScreenから遷移

## 受け入れ条件
- [ ] 局情報（局数、本場）を入力できる
- [ ] 各プレイヤーの得点変動を入力できる
- [ ] ツモ/ロン/流局を選択できる
- [ ] 入力内容をバリデーションできる
- [ ] 得点がデータベースに正しく保存される
- [ ] BoardScreenで累計得点が更新される
- [ ] エラーケースが適切にハンドリングされる

## 依存関係
- **前提条件**: なし（既存機能で実装可能）
- **後続タスク**: BL-002（得点計算機能）、BL-004（スコアボード表示）

## 見積もり
- **ストーリーポイント**: 8
- **作業時間**: 2-3日
- **難易度**: 中

## 補足
- 将来的には役の記録機能も追加予定だが、初回実装では得点のみフォーカス
- UIは既存のゲーム作成画面のデザインパターンを踏襲
- リアルタイム更新は後の機能で対応予定