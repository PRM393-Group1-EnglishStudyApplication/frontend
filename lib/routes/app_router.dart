import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/presentation/chat_page.dart';
import '../features/leaderboard/presentation/leaderboard_page.dart';
import '../features/learn/presentation/learn_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/vocabulary/presentation/vocabulary_page.dart';
import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.learn,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) => MainShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.learn,
                builder: (BuildContext context, GoRouterState state) =>
                    const LearnPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.vocabulary,
                builder: (BuildContext context, GoRouterState state) =>
                    const VocabularyPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.chat,
                builder: (BuildContext context, GoRouterState state) =>
                    const ChatPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.leaderboard,
                builder: (BuildContext context, GoRouterState state) =>
                    const LeaderboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  const AppRouter._();
}
