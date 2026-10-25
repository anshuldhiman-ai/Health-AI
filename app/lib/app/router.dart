import 'package:app/domain/entities/macro.dart';
import 'package:app/features/today/presentation/macro_breakdown_screen.dart';
import 'dart:math' as math;
import 'dart:ui';

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
        (state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/')) {
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
    // A floating toast has to clear this bar, and the bar is drawn by
    // THIS Scaffold while the toast is drawn by the nested Scaffold
    // inside `navigationShell`. Flutter's extendBody handling raises
    // the body's `padding.bottom` for the bar but leaves `viewPadding`
    // alone - and floating SnackBars position against `viewPadding`, so
    // without this they land behind the bar where their action cannot
    // be tapped. Only `viewPadding` is overridden, so nothing else in
    // the body shifts.
    final media = MediaQuery.of(context);
    final barHeight = AppSizing.navBarHeight + media.viewPadding.bottom;

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        // The scan disc sits IN the bar: the white ring cuts a notch
        // out of it, so roughly a third of the disc overlaps the dock.
        offset: const Offset(0, 20),
        child: _ScanButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.push('/scan');
          },
        ),
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
    final scheme = Theme.of(context).colorScheme;

    Widget destination({
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required int branchIndex,
    }) {
      final selected = navigationShell.currentIndex == branchIndex;
      final emerald = const Color(0xFF0F5A3C);
      final vibrantEmerald = const Color(0xFF1E885F);
      final color = selected ? (scheme.brightness == Brightness.dark ? scheme.primary : emerald) : scheme.onSurfaceVariant;
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
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.navLabel.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 2),
                if (selected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.brightness == Brightness.dark ? scheme.primary : vibrantEmerald,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: scheme.brightness == Brightness.dark
                    ? scheme.outlineVariant
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
              left: BorderSide(
                color: scheme.brightness == Brightness.dark
                    ? scheme.outlineVariant
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
              right: BorderSide(
                color: scheme.brightness == Brightness.dark
                    ? scheme.outlineVariant
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F5A3C).withValues(alpha: 0.06),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: AppSizing.navBarHeight,
              child: Row(
                children: [
                  destination(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    branchIndex: 0,
                  ),
                  destination(
                    icon: Icons.calendar_today_outlined,
                    selectedIcon: Icons.calendar_today_rounded,
                    label: 'Diary',
                    branchIndex: 1,
                  ),
                  // The scan button is docked over this span.
                  const SizedBox(width: 72),
                  destination(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart_rounded,
                    label: 'Insights',
                    branchIndex: 2,
                  ),
                  destination(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    branchIndex: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The raised scan action: deep emerald to vibrant emerald disc with a halo and leaf glyph.
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 60,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E885F), Color(0xFF0F5A3C)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F5A3C).withValues(alpha: 0.40),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
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
