import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/sleep_record.dart';
import 'package:app/l10n/app_localizations.dart';

/// Manual sleep log and seven-day history, opened from the dashboard's
/// sleep tile. No wearable or Health Connect sleep scope is required.
class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  static const _defaultBed = TimeOfDay(hour: 22, minute: 30);
  static const _defaultWake = TimeOfDay(hour: 6, minute: 30);

  late TimeOfDay _bed;
  late TimeOfDay _wake;

  @override
  void initState() {
    super.initState();
    final record = ref.read(sleepTodayProvider);
    _bed = _fromMinutes(record?.bedMinutes ?? _defaultBed.hour * 60 + 30);
    _wake = _fromMinutes(record?.wakeMinutes ?? _defaultWake.hour * 60 + 30);
  }

  TimeOfDay _fromMinutes(int minutes) =>
      TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);

  int get _bedMinutes => _bed.hour * 60 + _bed.minute;

  int get _wakeMinutes => _wake.hour * 60 + _wake.minute;

  int get _duration =>
      sleepDurationMinutes(bedMinutes: _bedMinutes, wakeMinutes: _wakeMinutes);

  Future<void> _pickTime({required bool bedtime}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: bedtime ? _bed : _wake,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (bedtime) {
        _bed = picked;
      } else {
        _wake = picked;
      }
    });
  }

  void _save() {
    ref
        .read(sleepProvider.notifier)
        .save(bedMinutes: _bedMinutes, wakeMinutes: _wakeMinutes);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.savedLabel)),
      );
  }

  void _clear() {
    ref.read(sleepProvider.notifier).removeToday();
    setState(() {
      _bed = _defaultBed;
      _wake = _defaultWake;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sleepProvider);
    final record = state.recordFor(DateTime.now());
    final progress = (_duration / SleepState.goalMinutes).clamp(0.0, 1.0);
    final goalLabel = formatSleepDuration(l10n, SleepState.goalMinutes);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x2,
            AppSpacing.screenPadding,
            AppSpacing.x8,
          ),
          children: [
            _Header(title: l10n.sleepTitle),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                children: [
                  Text(
                    l10n.sleepDuration,
                    style: AppTypography.itemS.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ProgressRing(
                    progress: progress,
                    size: 176,
                    strokeWidth: 14,
                    barColor: context.appColors.sleep,
                    semanticLabel:
                        '${formatSleepDuration(l10n, _duration)}, '
                        '${l10n.sleepGoal(goalLabel)}',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatSleepDuration(l10n, _duration),
                          style: AppTypography.value20.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.sleepGoal(
                            formatSleepDuration(l10n, SleepState.goalMinutes),
                          ),
                          style: AppTypography.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: _TimeTile(
                          label: l10n.bedtimeLabel,
                          value: _bed.format(context),
                          icon: Icons.bedtime_outlined,
                          onTap: () => _pickTime(bedtime: true),
                        ),
                      ),
                      Expanded(
                        child: _TimeTile(
                          label: l10n.wakeTimeLabel,
                          value: _wake.format(context),
                          icon: Icons.wb_sunny_outlined,
                          onTap: () => _pickTime(bedtime: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(l10n.saveSleep),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            if (record != null) ...[
              const SizedBox(height: 4),
              TextButton(onPressed: _clear, child: Text(l10n.clearSleep)),
            ],
            const SizedBox(height: 18),
            GroupHeader(title: l10n.last7Days),
            const SizedBox(height: 12),
            _WeekCard(days: state.recentDays(DateTime.now())),
            const SizedBox(height: 18),
            _NoteCard(text: l10n.sleepNote),
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

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Material(
      color: context.appColors.canvas,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 6,
                children: [
                  Icon(icon, size: 15, color: colors.sleep),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.itemS.copyWith(
                  color: scheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.days});

  final List<SleepDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final max = days.fold<int>(
      SleepState.goalMinutes,
      (m, d) => d.minutes > m ? d.minutes : m,
    );
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
                      days[i].minutes == 0
                          ? ''
                          : '${(days[i].minutes / 60).toStringAsFixed(1)}h',
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FractionallySizedBox(
                      heightFactor: days[i].minutes / max,
                      child: Container(
                        height: 76,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: i == days.length - 1
                              ? colors.sleep
                              : colors.sleep.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(7),
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

String formatSleepDuration(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l10n.durationMinutes('$rest');
  return l10n.durationHoursMinutes('$hours', '$rest');
}
