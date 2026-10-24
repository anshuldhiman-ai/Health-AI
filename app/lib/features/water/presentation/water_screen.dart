import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/preferences/water_controller.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/hydration.dart';
import 'package:app/l10n/app_localizations.dart';

/// Hydration detail opened from the dashboard's water tile. Intake and
/// the seven-day strip are stored locally; no cloud or account.
class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final water = ref.watch(waterTodayProvider);
    final notifier = ref.read(waterProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x2,
            AppSpacing.screenPadding,
            AppSpacing.x4,
          ),
          children: [
            _Header(title: 'Water Tracker'),
            const SizedBox(height: 14),
            _WaterWaveHeroCard(water: water),
            const SizedBox(height: 18),
            GroupHeader(title: l10n.waterIntake),
            const SizedBox(height: 10),
            const SizedBox(height: 14),
            _GlassGrid(glasses: water.glasses),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: notifier.addGlass,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.addGlass),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: water.glasses > 0 ? notifier.removeGlass : null,
              child: Text(l10n.removeGlass),
            ),
            const SizedBox(height: 18),
            GroupHeader(title: l10n.last7Days),
            const SizedBox(height: 12),
            _WeekCard(days: water.recentDays(DateTime.now())),
            const SizedBox(height: 18),
            _NoteCard(text: l10n.waterNote),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleL.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassGrid extends StatelessWidget {
  const _GlassGrid({required this.glasses});

  final int glasses;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 12,
        children: [
          for (var i = 0; i < HydrationState.goalGlasses; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 44,
              decoration: BoxDecoration(
                color: i < glasses
                    ? colors.water.withValues(alpha: 0.14)
                    : context.appColors.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: i < glasses ? colors.water : scheme.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(alignment: Alignment.center, children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: i < glasses ? 1 : 0),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                      builder: (context, fill, _) => Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: fill,
                          widthFactor: 1,
                          child: ColoredBox(color: colors.water.withValues(alpha: 0.45)),
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    i < glasses ? Icons.local_drink_rounded : Icons.local_drink_outlined,
                    size: 21,
                    color: i < glasses ? colors.water : scheme.onSurfaceVariant,
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.days});

  final List<HydrationDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final max = days.fold<int>(1, (m, d) => d.glasses > m ? d.glasses : m);
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: SizedBox(
        height: 128,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      days[i].glasses == 0 ? '' : '${days[i].glasses}',
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 76,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: max == 0
                              ? 0
                              : (days[i].glasses / max).clamp(0.0, 1.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: i == days.length - 1
                                  ? colors.water
                                  : colors.water.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      weekdays[days[i].date.weekday % 7],
                      style: AppTypography.caption.copyWith(
                        color: i == days.length - 1
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontWeight: i == days.length - 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentWash,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.accent),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The water visual only fills in response to logged glasses.
class _WaterWaveHeroCard extends StatelessWidget {
  const _WaterWaveHeroCard({required this.water});

  final HydrationState water;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayAmount = water.liters.toStringAsFixed(2);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 168,
          child: Stack(
            children: [
            if (water.glasses > 0)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: water.progress),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => CustomPaint(
                    painter: _WaterWavePainter(progress: progress),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today', style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(
                      displayAmount,
                      style: TextStyle(
                        fontFamily: AppTypography.family,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${water.glasses} / ${HydrationState.goalGlasses} glasses · ${water.glasses * HydrationState.mlPerGlass} ml',
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaterWavePainter extends CustomPainter {
  const _WaterWavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final level = size.height * (1 - progress.clamp(0.0, 1.0));
    final path = Path();
    path.moveTo(0, level);
    path.cubicTo(
      size.width * 0.25,
      level - size.height * 0.08,
      size.width * 0.65,
      level + size.height * 0.08,
      size.width,
      level,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x3348ABD9),
          Color(0x8848ABD9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    // Wave line top border
    final linePaint = Paint()
      ..color = const Color(0xFF48ABD9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final linePath = Path();
    linePath.moveTo(0, level);
    linePath.cubicTo(
      size.width * 0.25,
      level - size.height * 0.08,
      size.width * 0.65,
      level + size.height * 0.08,
      size.width,
      level,
    );
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) => oldDelegate.progress != progress;
}

