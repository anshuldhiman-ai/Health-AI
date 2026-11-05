import 'package:app/domain/entities/macro.dart';
import 'package:app/features/today/presentation/macro_breakdown_screen.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/design_system/components/unified_floating_nav_bar.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/activity/presentation/activity_screen.dart';
import 'package:app/features/diary/presentation/diary_screen.dart';
import 'package:app/features/insights/presentation/insights_screen.dart';
import 'package:app/features/insights/presentation/weekly_progress_screen.dart';
import 'package:app/features/onboarding/presentation/welcome_screen.dart';
import 'package:app/features/profile/presentation/goal_sheet.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:app/features/scan/presentation/scan_screen.dart';
import 'package:app/features/search/presentation/dish_detail_screen.dart';
import 'package:app/features/search/presentation/search_food_screen.dart';
import 'package:app/features/sleep/presentation/sleep_screen.dart';
import 'package:app/features/today/presentation/today_screen.dart';
import 'package:app/features/water/presentation/water_screen.dart';

/// Whether onboarding has already been completed on this device.
///
/// Set by [markWelcomeSeen] during bootstrap — i.e. BEFORE the router is
/// first built — so a returning user opens straight on Today instead of
/// flashing the welcome screen on every launch.
bool hasSeenWelcome = false;
final welcomeSeenNotifier = ValueNotifier<bool>(false);

void markWelcomeSeen() {
  hasSeenWelcome = true;
  welcomeSeenNotifier.value = true;
}

/// App routes (Section 10, navigation map). Welcome gates the shell;
/// five destinations: four tabs + the full-screen scan flow.
final appRouter = GoRouter(
  initialLocation: hasSeenWelcome ? '/today' : '/welcome',
  refreshListenable: welcomeSeenNotifier,
  redirect: (context, state) {
    if (hasSeenWelcome &&
        (state.matchedLocation == '/welcome' || state.matchedLocation == '/')) {
      return '/today';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _NavShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/diary', builder: (_, _) => const DiaryScreen()),
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
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ],
        ),
      ],
    ),
    GoRoute(path: '/activity', builder: (_, _) => const ActivityScreen()),
    GoRoute(path: '/water', builder: (_, _) => const WaterScreen()),
    GoRoute(path: '/sleep', builder: (_, _) => const SleepScreen()),
    GoRoute(path: '/weekly', builder: (_, _) => const WeeklyProgressScreen()),
    GoRoute(path: '/goals', builder: (_, _) => const GoalSettingsScreen()),
    GoRoute(
      path: '/search',
      builder: (_, state) => SearchFoodScreen(
        dayOffset: _dayFromQuery(state.uri.queryParameters['day']),
        initialMeal: _mealFromQuery(state.uri.queryParameters['meal']),
      ),
    ),
    GoRoute(
      path: '/dish/:id',
      builder: (_, state) => DishDetailScreen(
        dishId: Uri.decodeComponent(state.pathParameters['id'] ?? ''),
        dayOffset: _dayFromQuery(state.uri.queryParameters['day']),
        initialMeal: _mealFromQuery(state.uri.queryParameters['meal']),
      ),
    ),
    GoRoute(
      path: '/macro-breakdown',
      builder: (_, state) {
        final rawKind = state.uri.queryParameters['kind'];
        final kind = switch (rawKind) {
          'carbs' => MacroKind.carbs,
          'fat' || 'fats' => MacroKind.fat,
          _ => MacroKind.protein,
        };
        return MacroBreakdownScreen(initialKind: kind);
      },
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) {
        // Which meal/day is being logged decides the sheet's confirm
        // label and target; unknown values fall back to the current
        // clock and today.
        return ScanScreen(
          mealKind: _mealFromQuery(state.uri.queryParameters['meal']),
          dayOffset: _dayFromQuery(state.uri.queryParameters['day']),
        );
      },
    ),
  ],
);

MealKind _mealFromQuery(String? value) =>
    MealKind.values.asNameMap()[value] ?? mealForHour(DateTime.now().hour);

int _dayFromQuery(String? value) {
  final parsed = int.tryParse(value ?? '') ?? 0;
  return parsed.clamp(0, 179).toInt();
}

/// Floating white nav bar with rounded top corners and the raised
/// forest-green scan button (ref_ui.png).
///
/// Today | Diary | (SCAN) | Insights | Profile. The scan button is
/// CENTRED and docked into the bar (it overlaps the bar's top edge
/// with a white ring, reading as a notch) - not a floating button in
/// the corner.
class _NavShell extends StatelessWidget {
  const _NavShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final barHeight = 84.0 + media.viewPadding.bottom;

    return Scaffold(
      body: MediaQuery(
        data: media.copyWith(
          viewPadding: media.viewPadding.copyWith(
            bottom: math.max(media.viewPadding.bottom, barHeight),
          ),
        ),
        child: navigationShell,
      ),
      extendBody: true,
      bottomNavigationBar: UnifiedFloatingNavBar(
        navigationShell: navigationShell,
      ),
    );
  }
}
