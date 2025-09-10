# Task 002: 共通ドロップダウンコンポーネント - 専用コンポーネント実装

## タスク情報

- **タスクID**: task_002
- **作成日**: 2025-09-10
- **対象ファイル**: `lib/widgets/common_dropdown.dart`
- **関連する箇所**: ファイル末尾の `TODO(human)` 部分
- **ステータス**: 未完了

## Context（背景）

Riverpodと統合されたCommonDropdownコンポーネントの基盤実装が完了しました。現在の実装では以下の機能が利用可能です：

### 実装済み機能
- ✅ `CommonDropdown`: 基本ドロップダウンコンポーネント（Riverpod対応）
- ✅ `ProviderDropdown`: 同期プロバイダー用ドロップダウン
- ✅ `AsyncDropdown`: 非同期データ用ドロップダウン（ローディング/エラー状態対応）
- ✅ `CommonDropdownItem`: 一貫したアイテム作成ヘルパー

### 必要な専用コンポーネント
アプリケーション固有のドメインオブジェクトに対応した専用ドロップダウンコンポーネントが必要です。

## Your Task（実装すべき内容）

`common_dropdown.dart`ファイルの`TODO(human)`箇所で、以下の専用ドロップダウンコンポーネントを実装してください：

1. **UmaDropdown**: Uma枠（`../models/umaoka.dart`のUma enum用）
2. **GameDropdown**: ゲーム選択用（`../models/game.dart`のgamesProvider用）

### 実装箇所
```dart
// TODO(human): Add specialized dropdown components here
// Create UmaDropdown using your Uma enum from ../models/umaoka.dart
// Create GameDropdown using gamesProvider from ../models/game.dart
// Use ProviderDropdown for Uma (synchronous) and AsyncDropdown for Game (async database calls)
```

## Guidance（実装ガイダンス）

### UmaDropdown の実装

```dart
class UmaDropdown extends ConsumerWidget {
  final String label;
  final StateProvider<Uma?> valueProvider;
  // その他必要なプロパティ...
}
```

**実装要件:**
- `Uma` enumの全値を表示
- `ProviderDropdown`を基盤として使用（同期データのため）
- Uma枠のプロバイダーを作成して使用
- 簡潔なAPI（labelとvalueProviderのみで使用可能）

### GameDropdown の実装

```dart
class GameDropdown extends ConsumerWidget {
  final String label; 
  final StateProvider<Game?> valueProvider;
  // その他必要なプロパティ...
}
```

**実装要件:**
- 既存の`gamesProvider`（FutureProvider）を使用
- `AsyncDropdown`を基盤として使用（データベースアクセスのため）
- ゲームタイトルを表示テキストとして使用
- ローディング状態とエラー処理を含む

### プロバイダー実装

専用のプロバイダーも合わせて実装してください：

```dart
// Uma用のアイテムプロバイダー
final umaItemsProvider = Provider<List<DropdownMenuItem<Uma>>>((ref) {
  // Uma.values から DropdownMenuItem を生成
});

// Game用のアイテムプロバイダー  
final gameItemsProvider = FutureProvider<List<DropdownMenuItem<Game>>>((ref) async {
  // gamesProvider から DropdownMenuItem を生成
});
```

### デザイン要件

- 既存のAppColors使用
- 一貫したスタイリング
- アクセシビリティ対応
- エラーハンドリング

### 参考実装パターン

プロジェクト内の既存パターンを参考にしてください：
- `lib/providers/round_provider.dart`: StateNotifierPatternの使用例
- `lib/models/game.dart`: FutureProviderとRepository patternの使用例
- `lib/models/umaoka.dart`: enum定義パターン

## 実装完了の確認項目

- [ ] UmaDropdownの実装（ProviderDropdownベース）
- [ ] GameDropdownの実装（AsyncDropdownベース）
- [ ] umaItemsProviderの実装
- [ ] gameItemsProviderの実装
- [ ] 適切なimport文の追加
- [ ] 一貫したスタイリング
- [ ] エラーハンドリング

## 期待される使用例

実装完了後、以下のように簡単に使用できることを目指してください：

```dart
// Uma選択
UmaDropdown(
  label: 'ウマ設定',
  valueProvider: selectedUmaProvider,
)

// ゲーム選択  
GameDropdown(
  label: 'ゲーム選択',
  valueProvider: selectedGameProvider,
)
```

---

**注意**: このタスクが完了したら、`task_learning.md`のステータスを更新し、完了したタスクリストに移動してください。