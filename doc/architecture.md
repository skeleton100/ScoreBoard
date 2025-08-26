# ScoreBoard アーキテクチャドキュメント

## 概要
本ドキュメントは、ScoreBoardアプリ（麻雀記録アプリ）のアーキテクチャとフォルダ構造について説明します。

## 技術スタック
- **フレームワーク**: Flutter
- **状態管理**: flutter_riverpod
- **データベース**: sqflite (SQLite)
- **ルーティング**: go_router
- **アーキテクチャパターン**: Clean Architecture + MVVM

## lib/ フォルダ構造

### 📁 lib/
```
lib/
├── main.dart                 # アプリケーションのエントリーポイント
├── constants/               # 🆕 定数定義
├── core/                    # 🆕 コア機能
├── exceptions/              # 🆕 カスタム例外
├── extensions/              # 🆕 拡張メソッド
├── models/                  # データモデル
├── providers/               # 🆕 状態管理（Riverpod）
├── repositories/            # 🆕 データアクセス層
├── routes/                  # ルーティング設定
├── screens/                 # 画面（UI層）
├── services/                # ビジネスロジック・外部サービス
├── utils/                   # ユーティリティ
└── widgets/                 # 🆕 共通UIコンポーネント
```

### 📄 main.dart
- **役割**: アプリケーションのエントリーポイント
- **内容**: 
  - Providerスコープの設定
  - MaterialAppの設定
  - テーマとルーティングの初期化

### 📁 constants/ 🆕
> **新規追加**: 2025年8月26日

- **役割**: アプリケーション全体で使用する定数の管理
- **想定内容**:
  - デフォルト設定値
  - APIエンドポイント
  - 固定的な設定値
  - 文字列定数

### 📁 core/ 🆕
> **新規追加**: 2025年8月26日

- **役割**: アプリケーションのコア機能・基盤機能
- **想定内容**:
  - アプリケーション初期化
  - テーマ設定管理
  - 共通設定
  - アプリケーション設定

### 📁 exceptions/ 🆕
> **新規追加**: 2025年8月26日

- **役割**: カスタム例外クラスの定義
- **想定内容**:
  - データベース例外
  - ビジネスロジック例外
  - 入力バリデーション例外
  - ネットワーク例外

### 📁 extensions/ 🆕
> **新規追加**: 2025年8月26日

- **役割**: Dartの拡張メソッドの定義
- **想定内容**:
  - DateTime拡張
  - String拡張
  - Widget拡張
  - ユーティリティ拡張

### 📁 models/
- **役割**: データモデルとRepositoryの定義
- **現在の構造**:
  ```
  models/
  ├── database/           # データベース関連
  │   ├── database_helper.dart      # データベースヘルパー
  │   ├── migrations/               # マイグレーション
  │   │   └── migration_001.dart
  │   └── table_definitions.dart    # テーブル定義
  ├── game.dart          # ゲームモデル + Repository
  └── player.dart        # プレイヤーモデル + Repository
  ```

#### 📁 models/database/
- **database_helper.dart**: SQLiteデータベースの初期化・管理
- **migrations/**: データベースのマイグレーションスクリプト
- **table_definitions.dart**: テーブル構造の定義

#### 📄 models/game.dart
- Gameモデル（データクラス）
- GameRepository（データアクセス）
- Riverpodプロバイダー

#### 📄 models/player.dart
- Playerモデル（データクラス）
- PlayerRepository（データアクセス）
- Riverpodプロバイダー

### 📁 providers/ 🆕
> **新規追加**: 2025年8月26日（フォルダは存在していたが未使用）

- **役割**: Riverpodプロバイダーの定義・管理
- **想定内容**:
  - StateNotifierProvider
  - FutureProvider
  - StreamProvider
  - グローバル状態管理

### 📁 repositories/ 🆕
> **新規追加**: 2025年8月26日

- **役割**: データアクセス層の分離・管理
- **目的**: 
  - modelsからRepositoryクラスを分離
  - データソース（DB、API）の抽象化
  - テストの容易性向上
- **移行予定**:
  - GameRepository（models/game.dartから移行予定）
  - PlayerRepository（models/player.dartから移行予定）

### 📁 routes/
- **役割**: アプリケーションのルーティング設定
- **現在の構造**:
  ```
  routes/
  ├── app_routes.dart     # GoRouterの設定
  └── route_names.dart    # ルート名の定数
  ```

#### 📄 routes/app_routes.dart
- GoRouterプロバイダーの定義
- 画面遷移の設定
- ルートとWidgetのマッピング

#### 📄 routes/route_names.dart
- ルート名の定数定義
- 画面パスの管理

### 📁 screens/
- **役割**: 画面（UI層）の定義
- **現在の構造**:
  ```
  screens/
  ├── board/              # ゲーム盤面画面
  │   └── board_screen.dart
  ├── game_config/        # ゲーム設定画面
  │   ├── game_config_model.dart
  │   └── game_config_screen.dart
  ├── home/               # ホーム画面
  │   └── home_screen.dart
  └── setting/            # 設定画面
      └── setting_screen.dart
  ```

#### 📁 screens/board/
- **board_screen.dart**: ゲーム進行中のスコア表示画面

#### 📁 screens/game_config/
- **game_config_screen.dart**: 新しいゲームの設定画面
- **game_config_model.dart**: ゲーム設定用のモデルと状態管理

#### 📁 screens/home/
- **home_screen.dart**: アプリのメイン画面（ゲーム一覧表示）

#### 📁 screens/setting/
- **setting_screen.dart**: アプリの設定画面（UI骨格のみ実装済み）

### 📁 services/
- **役割**: ビジネスロジック・外部サービスとの連携
- **現在の構造**:
  ```
  services/
  └── database_service.dart    # データベースサービス
  ```

#### 📄 services/database_service.dart
- データベース操作の抽象化
- ビジネスロジックの実装

### 📁 utils/
- **役割**: ユーティリティ関数・ヘルパー
- **現在の構造**:
  ```
  utils/
  └── app_color.dart      # アプリ全体の色定義
  ```

#### 📄 utils/app_color.dart
- アプリケーション全体で使用する色の定義
- テーマカラーの統一管理

### 📁 widgets/ 🆕
> **新規追加**: 2025年8月26日（フォルダは存在していたが未使用）

- **役割**: 再利用可能なUIコンポーネントの定義
- **想定内容**:
  - カスタムボタン
  - 共通カード
  - ローディング表示
  - エラー表示コンポーネント

## アーキテクチャの特徴

### Clean Architecture
- **Presentation Layer**: screens/, widgets/
- **Domain Layer**: models/, services/
- **Data Layer**: repositories/, models/database/

### MVVM パターン
- **View**: screens/ (UI層)
- **ViewModel**: providers/ (状態管理)
- **Model**: models/ (データ層)

### 依存性注入
- **Riverpod**を使用したDependency Injection
- プロバイダーによる状態管理とサービス注入

## 今後の改善予定

### リファクタリング計画
1. **Repository分離**: models/からrepositories/への移行
2. **Provider整理**: providers/配下へのプロバイダー集約
3. **共通Widget作成**: widgets/配下への共通コンポーネント実装

### 拡張予定
1. **テスト構造**: test/配下のテストアーキテクチャ整備
2. **国際化**: l10n/配下の多言語対応
3. **設定管理**: core/配下での設定管理強化

## 設計原則

### 単一責任の原則
- 各フォルダ・ファイルは明確な役割を持つ
- 関心事の分離を重視

### 依存性逆転の原則
- 抽象に依存し、具象に依存しない
- インターフェースを通じた疎結合

### DRY原則
- 共通機能の再利用
- コードの重複排除

## 命名規則

### ファイル命名
- **スネークケース**: `file_name.dart`
- **画面**: `screen_name_screen.dart`
- **モデル**: `model_name.dart`
- **サービス**: `service_name_service.dart`

### クラス命名
- **パスカルケース**: `ClassName`
- **画面**: `ScreenNameScreen`
- **モデル**: `ModelName`
- **Repository**: `ModelNameRepository`

---

**作成日**: 2025年8月26日  
**最終更新**: 2025年8月26日  
**作成者**: Claude Code