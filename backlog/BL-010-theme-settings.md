# BL-010: テーマ設定機能

## 概要
アプリのテーマ（ライト・ダークモード）を設定する機能を実装する。

## 背景
現在のアプリは固定のライトテーマのみ対応している。ユーザビリティ向上とアクセシビリティ改善のため、ダークモード対応とテーマ切り替え機能が必要。

## 要件

### 機能要件
1. **テーマ選択**
   - ライトモード
   - ダークモード
   - システム設定に従う（自動）

2. **設定の保存**
   - ユーザー設定の永続化
   - アプリ起動時の設定復元

3. **リアルタイム切り替え**
   - 設定変更の即座反映
   - 全画面への適用

4. **既存UIとの整合性**
   - 全てのコンポーネントの対応
   - 既存のAppColorsとの統合

### 非機能要件
- 設定変更時のスムーズなアニメーション
- 全画面での一貫したテーマ適用
- パフォーマンスへの影響最小化

## 技術設計

### 設定管理
```dart
enum ThemeMode { light, dark, system }

class ThemeSettings {
  final ThemeMode themeMode;
  final bool useSystemTheme;
  
  ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.useSystemTheme = true,
  });
}

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  return ThemeSettingsNotifier();
});
```

### カラーパレット拡張
```dart
// lib/utils/app_color.dart の拡張
class AppColors {
  // 既存の色定義...
  
  // ダークモード用の色定義
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  
  // テーマ対応の動的色取得
  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : background;
      
  static Color getTextPrimaryColor(bool isDark) =>
      isDark ? darkTextPrimary : textPrimary;
}
```

### ThemeData設定
```dart
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      // 既存の設定...
    );
  }
  
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCardBackground,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
        // ...
      ),
    );
  }
}
```

### 設定の永続化
```dart
class ThemeSettingsRepository {
  static const String _themeKey = 'theme_mode';
  
  Future<ThemeSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    return ThemeSettings(themeMode: ThemeMode.values[themeIndex]);
  }
  
  Future<void> saveSettings(ThemeSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, settings.themeMode.index);
  }
}
```

## UI設計

### テーマ設定画面
現在のSettingScreenを拡張：
```dart
class SettingScreen extends ConsumerWidget {
  Widget _buildThemeSection(WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.palette),
            title: Text('テーマ'),
            subtitle: Text('アプリの外観を変更'),
          ),
          RadioListTile<ThemeMode>(
            title: Text('ライトモード'),
            value: ThemeMode.light,
            groupValue: ref.watch(themeSettingsProvider).themeMode,
            onChanged: (value) => _updateTheme(ref, value),
          ),
          RadioListTile<ThemeMode>(
            title: Text('ダークモード'),
            value: ThemeMode.dark,
            groupValue: ref.watch(themeSettingsProvider).themeMode,
            onChanged: (value) => _updateTheme(ref, value),
          ),
          RadioListTile<ThemeMode>(
            title: Text('システム設定に従う'),
            value: ThemeMode.system,
            groupValue: ref.watch(themeSettingsProvider).themeMode,
            onChanged: (value) => _updateTheme(ref, value),
          ),
        ],
      ),
    );
  }
}
```

### Main.dart の更新
```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final router = ref.watch(appRouter);
    
    return MaterialApp.router(
      title: 'Scoreboard App',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeSettings.themeMode,
      routerConfig: router,
    );
  }
}
```

## 既存画面の対応

### 色の動的取得
既存のハードコードされた色を動的取得に変更：
```dart
// Before
Text('テキスト', style: TextStyle(color: AppColors.textPrimary))

// After  
Text('テキスト', style: TextStyle(
  color: Theme.of(context).textTheme.bodyLarge?.color
))

// または
Consumer(
  builder: (context, ref, child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: AppColors.getBackgroundColor(isDark),
      // ...
    );
  }
)
```

### グラデーション対応
```dart
class AppGradients {
  static LinearGradient background(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark 
        ? [AppColors.darkBackground, AppColors.darkSurface]
        : [AppColors.background, AppColors.surface],
    );
  }
}
```

## 受け入れ条件
- [ ] ライトモード・ダークモードを選択できる
- [ ] システム設定に従うモードが動作する
- [ ] テーマ変更が全画面に即座に反映される
- [ ] 設定がアプリ再起動後も保持される
- [ ] 既存の全てのUIコンポーネントが両テーマで適切に表示される
- [ ] アニメーションがスムーズに動作する
- [ ] アクセシビリティが向上している（コントラスト比等）

## 依存関係
- **前提条件**: なし（既存機能で実装可能）
- **並行実装**: 他の機能と並行可能
- **後続タスク**: BL-011（多言語対応）

## 見積もり
- **ストーリーポイント**: 5
- **作業時間**: 1-2日
- **難易度**: 中

## 補足
- shared_preferencesパッケージの追加が必要
- 全ての既存画面の色指定の見直しが必要
- Material Design 3への対応も検討
- カスタムテーマの追加は将来検討