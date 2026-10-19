import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/l10n/app_localizations.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/diary/presentation/diary_screen.dart';
import 'package:app/features/insights/presentation/insights_screen.dart';
import 'package:app/features/onboarding/presentation/welcome_screen.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:app/features/scan/presentation/scan_screen.dart';
import 'package:app/features/today/presentation/today_screen.dart';

/// App routes (Section 10, navigation map). Welcome gates the shell;
/// five destinations: four tabs + the full-screen scan flow.
final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _NavShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (_, _) => const TodayScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/diary',
              builder: (_, _) => const DiaryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/insights',
              builder: (_, _) => const InsightsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) {
        // Which meal is being logged decides the sheet's confirm
        // label; unknown values fall back to lunch.
        final mealParam = state.uri.queryParameters['meal'];
        final meal = MealKind.values.asNameMap()[mealParam] ??
            MealKind.lunch;
        return ScanScreen(mealKind: meal);
      },
    ),
  ],
);

/// Bottom navigation with the centre scan button (ref_ui.png).
///
/// Today | Diary | (SCAN) | Insights | Profile. The scan button always
/// pushes the camera flow; it is not a selectable branch.
class _NavShell extends StatelessWidget {
  const _NavShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        // TODO(M2): this is the scan entry; camera lands there.
        onPressed: () => context.push('/scan'),
        shape: const CircleBorder(),
        child: const Icon(Icons.document_scanner_outlined),
      ),
      bottomNavigationBar: _BottomBar(
        navigationShell: navigationShell,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget destination(
      IconData icon,
      String label,
      String path,
      int branchIndex,
    ) {
      final selected =
          navigationShell.currentIndex == branchIndex;
      return InkWell(
        onTap: () => navigationShell.goBranch(
          branchIndex,
          initialLocation: branchIndex == navigationShell.currentIndex,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: scheme.outline),
            ),
          ),
          child: Row(
            children: [
              const _NavGap(),
              destination(
                Icons.today_outlined,
                l10n.todayTab,
                '/today',
                0,
              ),
              const _NavGap(),
              destination(
                Icons.book_outlined,
                l10n.diaryTab,
                '/diary',
                1,
              ),
              // The scan FAB sits docked over this empty span.
              const SizedBox(width: 72),
              destination(
                Icons.query_stats_outlined,
                l10n.insightsTab,
                '/insights',
                2,
              ),
              const _NavGap(),
              destination(
                Icons.person_outline,
                l10n.profileTab,
                '/profile',
                3,
              ),
              const _NavGap(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavGap extends StatelessWidget {
  const _NavGap();

  @override
  Widget build(BuildContext context) {
    return const Expanded(child: SizedBox.shrink());
  }
}
