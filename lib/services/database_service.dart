import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/database/database_helper.dart';

class DatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // データベース初期化
  Future<void> initialize() async {
    await _dbHelper.database;
  }

  // データベースの状態確認
  Future<bool> isDatabaseReady() async {
    return await _dbHelper.isDatabaseOpen();
  }

  // データベース情報取得
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final tableNames = await _dbHelper.getTableNames();
    final rowCounts = await _dbHelper.getTableRowCounts();
    
    return {
      'tableNames': tableNames,
      'rowCounts': rowCounts,
      'isOpen': await _dbHelper.isDatabaseOpen(),
    };
  }

  // データベースを閉じる
  Future<void> close() async {
    await _dbHelper.close();
  }

  // データベースを削除（開発時のみ）
  Future<void> deleteDatabase() async {
    await _dbHelper.deleteDatabase();
  }
}

// Riverpod Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final databaseInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(databaseServiceProvider);
  await service.initialize();
  return await service.getDatabaseInfo();
}); 