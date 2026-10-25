import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/l10n/app_localizations.dart';

/// Detailed on-device activity: steps, distance, active time, pace,
/// cadence, hourly movement and a seven-day history. Opened from the
/// dashboard's steps tile; it has no duplicate quick-log controls.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final value = ref.watch(stepTrackerProvider);

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
            _Header(title: l10n.activityTitle),
            const SizedBox(height: 14),
            value.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _StatusCard(
                icon: Icons.directions_walk_rounded,
                title: l10n.activityUnavailableTitle,
                body: l10n.activityUnavailableBody,
                actionLabel: l10n.activityRefresh,
                onAction: () => ref.invalidate(stepTrackerProvider),
              ),
              data: (snapshot) => switch (snapshot.status) {
                StepStatus.live => _LiveActivity(snapshot: snapshot),
                StepStatus.permissionDenied => _PermissionCard(
                  onGranted: () => ref.invalidate(stepTrackerProvider),
                ),
                StepStatus.unsupported => _StatusCard(
                  icon: Icons.sensors_off_rounded,
                  title: l10n.activityUnsupportedTitle,
                  body: l10n.activityUnsupportedBody,
                ),
                StepStatus.unavailable => _StatusCard(
                  icon: Icons.directions_walk_rounded,
                  title: l10n.activityUnavailableTitle,
                  body: l10n.activityUnavailableBody,
                  actionLabel: l10n.activityRefresh,
                  onAction: () => ref.invalidate(stepTrackerProvider),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveActivity extends StatelessWidget {
  const _LiveActivity({required this.snapshot});

  final StepSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(snapshot: snapshot),
        const SizedBox(height: 14),
        _MetricsGrid(snapshot: snapshot),

        const SizedBox(height: 20),
        GroupHeader(title: l10n.todayByHour),
        const SizedBox(height: 12),
        _HourlyCard(hourly: snapshot.hourlySteps),
        const SizedBox(height: 24),
        GroupHeader(title: l10n.last7Days),
        const SizedBox(height: 12),
        _HistoryCard(history: snapshot.history),
        const SizedBox(height: 18),
        _NoteCard(text: l10n.activityPrivacyNote),
      ],
    );
  }
}


class _Header extends ConsumerWidget {
  const _Header({required this.title});

  final String title;

  Future<void> _showSetStepGoalSheet(BuildContext context, WidgetRef ref) async {
    final currentGoal = ref.read(stepGoalProvider);
    var selected = currentGoal;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final scheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set Daily Step Goal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Consistent daily walking boosts metabolic health.',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: selected > 2000
                            ? () => setSheetState(() => selected -= 1000)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            formatCount(selected),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            'steps per day',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      IconButton.filledTonal(
                        onPressed: selected < 30000
                            ? () => setSheetState(() => selected += 1000)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    children: [6000, 8000, 10000, 12000, 15000].map((g) {
                      final isSel = selected == g;
                      return ChoiceChip(
                        label: Text('${g ~/ 1000}k'),
                        selected: isSel,
                        onSelected: (_) => setSheetState(() => selected = g),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      await ref.read(stepGoalProvider.notifier).setGoal(selected);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Save Step Goal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
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
            'Step Counter & Activity',
            style: AppTypography.titleL.copyWith(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Set Step Goal',
          onPressed: () => _showSetStepGoalSheet(context, ref),
          icon: Icon(Icons.tune_rounded, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.snapshot});

  final StepSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final stepGoal = ref.watch(stepGoalProvider);
    final displaySteps = snapshot.steps;
    final progress = (displaySteps / stepGoal).clamp(0.0, 1.0);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          ProgressRing(
            progress: progress,
            size: 190,
            strokeWidth: 15,
            // Theme tokens, so the ring keeps its progression in dark
            // mode instead of going muddy against the dark surface.
            gradientColors: [
              colors.primary,
              colors.success,
              colors.water,
              colors.accent,
            ],
            semanticLabel:
                '${formatCount(displaySteps)} ${l10n.stepsLabel}, '
                '${(progress * 100).round()}% ${l10n.progressLabel}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daily steps',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCount(displaySteps),
                  style: TextStyle(
                    fontFamily: AppTypography.family,
                    color: scheme.onSurface,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCount(stepGoal)} steps goal',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.snapshot});

  final StepSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final distance = snapshot.distanceKm;
    final activeMinutes = snapshot.activeSeconds ~/ 60;

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.location_on_outlined,
            label: 'Distance',
            value: '${distance.toStringAsFixed(1)} km',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.access_time_rounded,
            label: 'Active Time',
            value: '$activeMinutes mins',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: colors.primary),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.itemS.copyWith(
              color: scheme.onSurface,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyCard extends StatelessWidget {
  const _HourlyCard({required this.hourly});

  final List<int> hourly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final buckets = <int>[
      for (var i = 0; i < 24; i += 4)
        if (i + 4 <= hourly.length)
          hourly.sublist(i, i + 4).fold(0, (sum, value) => sum + value)
        else
          0,
    ];
    final max = buckets.fold<int>(0, (m, v) => v > m ? v : m);
    const labels = ['00', '04', '08', '12', '16', '20'];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          buckets[i] == 0 ? '' : compactCount(buckets[i]),
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 9.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 74,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: max == 0
                                  ? 0
                                  : (buckets[i] / max).clamp(0.0, 1.0),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: i == buckets.length - 1
                                      ? scheme.primary
                                      : scheme.primary.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (max == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.historyBuildsHint,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});

  final List<DaySteps> history;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final max = history.fold<int>(0, (m, d) => d.steps > m ? d.steps : m);
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < history.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          history[i].steps == 0
                              ? ''
                              : compactCount(history[i].steps),
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 9.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 82,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: max == 0
                                  ? 0
                                  : (history[i].steps / max).clamp(0.0, 1.0),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: i == history.length - 1
                                      ? scheme.primary
                                      : scheme.primary.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weekdays[history[i].date.weekday % 7],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: i == history.length - 1
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight: i == history.length - 1
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
          if (max == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.historyBuildsHint,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
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
    final scheme = Theme.of(context).colorScheme;
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
                color: scheme.onSurface,
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onGranted});

  final VoidCallback onGranted;

  Future<void> _request(BuildContext context) async {
    final granted = await requestStepPermission();
    if (granted) {
      onGranted();
      return;
    }
    if (!context.mounted) return;
    await openStepPermissionSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StatusCard(
      icon: Icons.directions_walk_rounded,
      title: l10n.activityPermissionTitle,
      body: l10n.activityPermissionBody,
      actionLabel: l10n.activityAllow,
      onAction: () => _request(context),
      secondaryLabel: l10n.activityOpenSettings,
      onSecondary: openStepPermissionSettings,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final Future<bool> Function()? onSecondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primaryWash,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleM.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyM.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: () async {
                await onSecondary!();
              },
              child: Text(secondaryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

String formatActiveTime(AppLocalizations l10n, int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes < 60) return l10n.durationMinutes('$minutes');
  return l10n.durationHoursMinutes('${minutes ~/ 60}', '${minutes % 60}');
}

String formatPace(double minutesPerKm) {
  var minutes = minutesPerKm.floor();
  var seconds = ((minutesPerKm - minutes) * 60).round();
  if (seconds >= 60) {
    minutes += 1;
    seconds = 0;
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
