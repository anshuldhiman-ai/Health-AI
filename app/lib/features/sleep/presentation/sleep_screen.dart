import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/app_toast.dart';
import 'package:app/design_system/components/group_header.dart';
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
    AppToast.show(
      ScaffoldMessenger.of(context),
      message: AppLocalizations.of(context)!.savedLabel,
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
            _Header(title: 'Sleep Tracker'),
            const SizedBox(height: 14),
            _SleepBadgesRow(),
            const SizedBox(height: 14),
            _ClockDialCard(
              bed: _bed,
              wake: _wake,
              onPickBed: () => _pickTime(bedtime: true),
              onPickWake: () => _pickTime(bedtime: false),
            ),
            const SizedBox(height: 14),
            _SmartAlarmCard(),
            const SizedBox(height: 14),
            _AverageSnoozeCard(),
            const SizedBox(height: 14),
            _RecommendationsCard(),
            const SizedBox(height: 18),
            GroupHeader(title: l10n.last7Days),
            const SizedBox(height: 12),
            _WeekCard(days: state.recentDays(DateTime.now())),
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
            const SizedBox(height: 14),
            _NoteCard(text: l10n.sleepNote),
          ],
        ),
      ),
    );
  }
}

class _SleepBadgesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF382C62), Color(0xFF4C3D82)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Restful hours',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '35.11 hours',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.bedtime_rounded, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E284A), Color(0xFF2C3966)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sleep',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '86 hours',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.nightlight_round, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClockDialCard extends StatelessWidget {
  const _ClockDialCard({
    required this.bed,
    required this.wake,
    required this.onPickBed,
    required this.onPickWake,
  });

  final TimeOfDay bed;
  final TimeOfDay wake;
  final VoidCallback onPickBed;
  final VoidCallback onPickWake;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Bedtime & Wake Time',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular golden gradient dial track
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                        width: 14,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(176, 176),
                    painter: _ClockDialArcPainter(
                      goldColor: colors.gold,
                      arcColor: const Color(0xFF0D5C3A),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bed.format(context),
                        style: TextStyle(
                          fontFamily: AppTypography.family,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'PM',
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: onPickBed,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.bedtime_outlined, size: 18, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 6),
                      Text(
                        'Bed: ${bed.format(context)}',
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onPickWake,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 18, color: Color(0xFF4CC18F)),
                      const SizedBox(width: 6),
                      Text(
                        'Wake: ${wake.format(context)}',
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockDialArcPainter extends CustomPainter {
  const _ClockDialArcPainter({required this.goldColor, required this.arcColor});

  final Color goldColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - 14) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [goldColor, arcColor, goldColor],
      ).createShader(rect);

    // Draw active arc from 10:30 PM (around 7 o'clock) to 6:30 AM (around 2 o'clock)
    canvas.drawArc(rect, 0.8, 3.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmartAlarmCard extends StatefulWidget {
  @override
  State<_SmartAlarmCard> createState() => _SmartAlarmCardState();
}

class _SmartAlarmCardState extends State<_SmartAlarmCard> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5C3A).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_rounded, color: Color(0xFF0D5C3A), size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Alarm',
                style: AppTypography.itemTitle.copyWith(
                  color: scheme.onSurface,
                  fontSize: 15,
                ),
              ),
              Text(
                'Toggles immediate alarm',
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Switch(
            value: _enabled,
            activeColor: const Color(0xFF0D5C3A),
            onChanged: (val) => setState(() => _enabled = val),
          ),
        ],
      ),
    );
  }
}

class _AverageSnoozeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Analytics',
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average snooze data',
                    style: AppTypography.itemTitle.copyWith(
                      color: scheme.onSurface,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '2 Snoozes (18 min)',
                    style: AppTypography.itemS.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Color(0xFFD4AF37), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalized recommendations',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Golden sleep quality badges',
                  style: AppTypography.itemS.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
                    SizedBox(
                      height: 76,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: max == 0
                              ? 0
                              : (days[i].minutes / max).clamp(0.0, 1.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: i == days.length - 1
                                  ? colors.sleep
                                  : colors.sleep.withValues(alpha: 0.35),
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

String formatSleepDuration(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l10n.durationMinutes('$rest');
  return l10n.durationHoursMinutes('$hours', '$rest');
}
