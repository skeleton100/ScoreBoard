import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/board/board_screen.dart';
import '../screens/game_config/game_config_screen.dart';
import '../screens/setting/setting_screen.dart';
import 'route_names.dart';

final appRouter = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.board,
        builder: (context, state) => const BoardScreen(),
      ),
      GoRoute(
        path: RouteNames.gameConfig,
        builder: (context, state) => const GameConfigScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingScreen(),
      ),
    ],
  );
});