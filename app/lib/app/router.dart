import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/activity/presentation/activity_screen.dart';
import 'package:app/features/diary/presentation/diary_screen.dart';
import 'package:app/features/insights/presentation/insights_screen.dart';
import 'package:app/features/insights/presentation/weekly_progress_screen.dart';
import 'package:app/features/onboarding/presentation/welcome_screen.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:app/features/scan/presentation/scan_screen.dart';
import 'package:app/features/search/presentation/dish_detail_screen.dart';
import 'package:app/features/search/presentation/search_food_screen.dart';
import 'package:app/features/sleep/presentation/sleep_screen.dart';
import 'package:app/features/today/presentation/today_screen.dart';
import 'package:app/features/water/presentation/water_screen.dart';

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
      floatingActionButton: _ScanButton(
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          context.push('/scan');
        },
      ),
      bottomNavigationBar: _BottomBar(navigationShell: navigationShell),
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

    Widget destination({
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required int branchIndex,
    }) {
      final selected = navigationShell.currentIndex == branchIndex;
      final color = selected ? scheme.primary : scheme.onSurfaceVariant;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              navigationShell.goBranch(
                branchIndex,
                initialLocation: branchIndex == navigationShell.currentIndex,
              );
            },
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? selectedIcon : icon, size: 23, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppTypography.navLabel.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.nav,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              destination(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: l10n.todayTab,
                branchIndex: 0,
              ),
              destination(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: l10n.diaryTab,
                branchIndex: 1,
              ),
              // The scan button is docked over this span.
              const SizedBox(width: 64),
              destination(
                icon: Icons.bar_chart_rounded,
                selectedIcon: Icons.bar_chart_rounded,
                label: l10n.insightsTab,
                branchIndex: 2,
              ),
              destination(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: l10n.profileTab,
                branchIndex: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised scan action: forest-green disc with a white halo and a
/// viewfinder + leaf glyph.
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 56,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 3),
          boxShadow: AppShadows.scanButton,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(painter: _ScanGlyphPainter()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded viewfinder corners with a leaf at the centre.
class _ScanGlyphPainter extends CustomPainter {
  const _ScanGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const inset = 1.5;
    const arm = 6.5;
    const radius = 4.0;

    void corner(double x, double y, double dx, double dy) {
      final path = Path()
        ..moveTo(x + dx * arm, y)
        ..lineTo(x + dx * radius, y)
        ..quadraticBezierTo(x, y, x, y + dy * radius)
        ..lineTo(x, y + dy * arm);
      canvas.drawPath(path, paint);
    }

    corner(inset, inset, 1, 1);
    corner(s - inset, inset, -1, 1);
    corner(inset, s - inset, 1, -1);
    corner(s - inset, s - inset, -1, -1);

    // Leaf (filled) at the centre.
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(math.pi / 4);
    final leaf = Path()
      ..moveTo(0, 5.4)
      ..cubicTo(-5.6, 1.6, -3.8, -4.6, 0, -5.6)
      ..cubicTo(3.8, -4.6, 5.6, 1.6, 0, 5.4)
      ..close();
    canvas.drawPath(leaf, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScanGlyphPainter oldDelegate) => false;
}
