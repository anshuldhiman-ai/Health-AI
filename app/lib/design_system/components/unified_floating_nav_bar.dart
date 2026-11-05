import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/l10n/app_localizations.dart';

/// Unified Floating Pill Navigation Bar recreated from the premium dark
/// fitness dashboard specification (step.png).
///
/// Layout:
/// `[ Home | Diary | SCAN | Insights | Profile ]`
///
/// Features:
/// - Floating dark pill container (#041F1C at 95% opacity) with thin #104038 border
/// - Raised circular glowing mint (#00E5A3) SCAN button in the center
/// - Smooth 60 FPS performance without heavy backdrop filters that stall the GPU
/// - Isolated via RepaintBoundary for lag-free scrolling and screen transitions
/// - Supports both StatefulNavigationShell (in app router) and standalone routes (e.g. ActivityScreen)
class UnifiedFloatingNavBar extends StatelessWidget {
  const UnifiedFloatingNavBar({
    super.key,
    this.navigationShell,
    this.activeBranchIndex,
  });

  /// Injected when used inside StatefulShellRoute (_NavShell).
  final StatefulNavigationShell? navigationShell;

  /// Explicit active branch index (0: Home, 1: Diary, 2: Insights, 3: Profile)
  /// when used on a standalone screen outside StatefulShellRoute.
  final int? activeBranchIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeLabel = l10n?.todayTab ?? 'Home';
    final diaryLabel = l10n?.diaryTab ?? 'Diary';
    final insightsLabel = l10n?.insightsTab ?? 'Insights';
    final profileLabel = l10n?.profileTab ?? 'Profile';

    final currentIndex = navigationShell?.currentIndex ?? activeBranchIndex ?? 0;

    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Floating dark pill container
                Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFF041F1C).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(
                      color: const Color(0xFF104038),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00110E).withValues(alpha: 0.60),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 0: Home / Today
                      _NavBarItem(
                        icon: Icons.home_rounded,
                        label: homeLabel,
                        isActive: currentIndex == 0,
                        onTap: () => _onNavigate(context, 0, '/today'),
                      ),

                      // 1: Diary
                      _NavBarItem(
                        icon: Icons.menu_book_rounded,
                        label: diaryLabel,
                        isActive: currentIndex == 1,
                        onTap: () => _onNavigate(context, 1, '/diary'),
                      ),

                      // Spacer for the raised SCAN button
                      const SizedBox(width: 58),

                      // 2: Insights
                      _NavBarItem(
                        icon: Icons.bar_chart_rounded,
                        label: insightsLabel,
                        isActive: currentIndex == 2,
                        onTap: () => _onNavigate(context, 2, '/insights'),
                      ),

                      // 3: Profile
                      _NavBarItem(
                        icon: Icons.person_outline_rounded,
                        label: profileLabel,
                        isActive: currentIndex == 3,
                        onTap: () => _onNavigate(context, 3, '/profile'),
                      ),
                    ],
                  ),
                ),

                // Center Raised Circular SCAN Button with mint glowing ring
                Positioned(
                  top: -4,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      context.push('/scan');
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF012924),
                        border: Border.all(
                          color: const Color(0xFF00E5A3),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5A3).withValues(alpha: 0.40),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.crop_free_rounded,
                          color: Color(0xFF00E5A3),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNavigate(BuildContext context, int branchIndex, String routePath) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (navigationShell != null) {
      navigationShell!.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell!.currentIndex,
      );
    } else {
      context.go(routePath);
    }
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00D6A0);
    const inactiveColor = Color(0xFF7E9A94);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(0, isActive ? -1 : 0, 0),
                child: Icon(
                  icon,
                  size: 23,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: isActive ? 4 : 0,
                height: 4,
                decoration: const BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
