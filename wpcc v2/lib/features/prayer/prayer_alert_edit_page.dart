import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_back.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_reveal.dart';
import '../../core/widgets/member_shimmer.dart';
import 'prayer_alerts_content.dart';
import 'prayer_repository.dart';
import 'prayer_schedule.dart';

class PrayerAlertEditPage extends StatefulWidget {
  const PrayerAlertEditPage({super.key, this.alertId, this.alert});

  final String? alertId;
  final Map<String, dynamic>? alert;

  @override
  State<PrayerAlertEditPage> createState() => _PrayerAlertEditPageState();
}

class _PrayerAlertEditPageState extends State<PrayerAlertEditPage> {
  final PrayerRepository repo = PrayerRepository();
  late final TextEditingController title = TextEditingController();
  Map<String, dynamic>? alert;
  TimeOfDay time = const TimeOfDay(hour: 6, minute: 0);
  Set<int> days = {1, 2, 3, 4, 5, 6, 7};
  bool hasDuration = false;
  double durationMinutes = 30;
  bool vibrationEnabled = true;
  int? snoozeMinutes;
  bool loading = false;
  String? loadError;
  bool saving = false;

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    alert = widget.alertId == null ||
            widget.alert?['id']?.toString() == widget.alertId
        ? widget.alert
        : null;
    if (alert != null) {
      _applyAlert(alert!);
    } else if (widget.alertId != null) {
      loading = true;
      _loadAlert();
    } else {
      title.text = 'Prayer';
    }
  }

  Future<void> _loadAlert() async {
    try {
      final rows = await repo.alerts();
      final matches = rows.where(
        (row) => row['id']?.toString() == widget.alertId,
      );
      if (!mounted) return;
      if (matches.isEmpty) {
        setState(() {
          loading = false;
          loadError = 'Prayer alert not found.';
        });
        return;
      }
      setState(() {
        alert = matches.first;
        _applyAlert(alert!);
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          loadError = 'Unable to load this prayer alert.';
        });
      }
    }
  }

  void _applyAlert(Map<String, dynamic> value) {
    title.text = value['title']?.toString() ?? 'Prayer';
    time = _timeFrom(value);
    days = Set<int>.from(
      ((value['days_of_week'] as List?) ?? const [1, 2, 3, 4, 5, 6, 7]).map(
        (e) => e as int,
      ),
    );
    hasDuration = value['duration_seconds'] != null;
    durationMinutes = ((value['duration_seconds'] as int?) ?? 1800) / 60;
    vibrationEnabled = value['vibration_enabled'] != false;
    snoozeMinutes = int.tryParse(value['snooze_minutes']?.toString() ?? '');
  }

  TimeOfDay _timeFrom(Map<String, dynamic> value) {
    final raw = value['local_time']?.toString() ?? '06:00:00';
    final parts = raw.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.firstOrNull ?? '') ?? 6,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (loading || (widget.alertId != null && alert == null)) return;
    if (title.text.trim().isEmpty) {
      _show('Add a label for this prayer alert.');
      return;
    }
    if (days.isEmpty) {
      _show('Select at least one repeat day.');
      return;
    }

    setState(() => saving = true);
    try {
      await repo.save(
        id: alert?['id']?.toString(),
        scope: 'personal',
        title: title.text.trim(),
        timezone: 'Africa/Lagos',
        localTime:
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
        days: days.toList()..sort(),
        durationSeconds: hasDuration ? durationMinutes.round() * 60 : null,
        audioUrl: alert?['audio_url']?.toString(),
        audioTitle: alert?['audio_title']?.toString(),
        audioSource: alert?['audio_source']?.toString(),
        vibrationEnabled: vibrationEnabled,
        snoozeMinutes: snoozeMinutes,
        branchId: null,
        departmentId: null,
      );
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) _show(error.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickTime() async {
    final next = await showTimePicker(context: context, initialTime: time);
    if (next != null && mounted) setState(() => time = next);
  }

  /// "Rings in 2 h 15 min", from the time and days chosen right now.
  String _ringsText() {
    if (days.isEmpty) return 'Choose at least one day';
    final next = PrayerSchedule.nextOf({
      'local_time': '${time.hour}:${time.minute}',
      'days_of_week': days.toList(),
      'timezone': 'Africa/Lagos',
    }, DateTime.now());
    if (next == null) return '';
    final label = PrayerSchedule.countdown(next);
    if (label == 'Now') return 'Rings now';
    if (label.startsWith('In ')) return 'Rings in ${label.substring(3)}';
    if (label == 'Tomorrow') return 'Rings tomorrow';
    return 'Rings on $label';
  }

  @override
  Widget build(BuildContext context) {
    final gutter = MemberBackScope.gutter(context);
    if (loading) {
      return Scaffold(
        appBar: const MemberAppBar(),
        body: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
          child: const MemberShimmer(
            label: 'Loading prayer alert',
            child: Column(children: [
              MemberBone(height: 148, radius: 20),
              SizedBox(height: 20),
              MemberBone(height: 52, radius: 12),
              SizedBox(height: 20),
              MemberBone(height: 48, radius: 24),
            ]),
          ),
        ),
      );
    }
    if (loadError != null) {
      return Scaffold(
        appBar: const MemberAppBar(),
        body: Center(
          child: MemberStatus(
            message: loadError!,
            icon: PhosphorIconsRegular.warningCircle,
            onRetry: () {
              setState(() {
                loading = true;
                loadError = null;
              });
              _loadAlert();
            },
          ),
        ),
      );
    }
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final rings = _ringsText();
    return Scaffold(
      appBar: MemberAppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.alertId == null && alert == null
              ? 'New prayer alert'
              : 'Edit prayer alert',
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          gutter,
          8,
          gutter,
          keyboardOpen
              ? 12
              : math.max(12, MediaQuery.paddingOf(context).bottom),
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
                child: saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
            children: [
              Semantics(
                button: true,
                excludeSemantics: true,
                label: 'Prayer alert time',
                value: time.format(context),
                onTap: _pickTime,
                child: MemberPress(
                  child: Material(
                    color: colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _pickTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 16),
                        child: Column(
                          children: [
                            Center(
                              child: PrayerTimeText(
                                hour: time.hour,
                                minute: time.minute,
                                size: 64,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rings.isEmpty ? 'Tap to change the time' : rings,
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Label', style: text.labelLarge),
              const SizedBox(height: 8),
              Semantics(
                label: 'Label',
                child: TextField(
                  controller: title,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Prayer'),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: Text('Repeat', style: text.labelLarge)),
                  Text(
                    PrayerSchedule.daysLabel(days.toList()),
                    textAlign: TextAlign.end,
                    style: text.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Seven 48px targets need 336px. On narrower screens the row
              // borrows up to 8px from each gutter; the circles stay 40px.
              LayoutBuilder(
                builder: (context, box) {
                  final extra = ((48 * 7 - box.maxWidth) / 2).clamp(0.0, 8.0);
                  return SizedBox(
                    height: 48,
                    child: OverflowBox(
                      minWidth: box.maxWidth + 2 * extra,
                      maxWidth: box.maxWidth + 2 * extra,
                      child: Row(
                        children: [
                          for (var index = 0; index < 7; index++)
                            Expanded(
                              child: PrayerDayToggle(
                                letter: PrayerDayStrip.letters[index],
                                name: _dayNames[index],
                                selected: days.contains(index + 1),
                                onChanged: (selected) => setState(() {
                                  if (selected) {
                                    days.add(index + 1);
                                  } else {
                                    days.remove(index + 1);
                                  }
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              MemberExpand(
                child: days.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Select at least one repeat day.',
                          style: text.bodySmall?.copyWith(color: colors.error),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    _SettingRow(
                      title: 'Prayer duration',
                      subtitle: hasDuration
                          ? '${durationMinutes.round()} minutes · countdown'
                          : 'No duration · count up',
                      value: hasDuration,
                      onChanged: (value) => setState(() => hasDuration = value),
                    ),
                    MemberExpand(
                      child: hasDuration
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Slider(
                                min: 5,
                                max: 120,
                                divisions: 23,
                                value: durationMinutes.clamp(5, 120),
                                label: '${durationMinutes.round()} min',
                                onChanged: (value) =>
                                    setState(() => durationMinutes = value),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    _SettingRow(
                      title: 'Vibration',
                      subtitle:
                          'Used by supported installed PWA/browser notifications',
                      value: vibrationEnabled,
                      onChanged: (value) =>
                          setState(() => vibrationEnabled = value),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<int?>(
                        initialValue: snoozeMinutes,
                        decoration: const InputDecoration(labelText: 'Snooze'),
                        items: const [
                          DropdownMenuItem<int?>(
                              value: null, child: Text('Off')),
                          DropdownMenuItem<int?>(
                              value: 5, child: Text('5 minutes')),
                          DropdownMenuItem<int?>(
                              value: 10, child: Text('10 minutes')),
                          DropdownMenuItem<int?>(
                              value: 15, child: Text('15 minutes')),
                          DropdownMenuItem<int?>(
                              value: 30, child: Text('30 minutes')),
                        ],
                        onChanged: (value) =>
                            setState(() => snoozeMinutes = value),
                      ),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.musicNotes,
                              size: 20, color: colors.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sound / playlist',
                                    style: text.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  alert?['audio_title']?.toString() ??
                                      'No published prayer audio selected',
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: saving
                      ? null
                      : () => _show(
                            'Save this alert first, then open it from Prayer alerts to test the full session.',
                          ),
                  icon: const Icon(PhosphorIconsRegular.speakerHigh, size: 18),
                  label: const Text('Test prayer alert'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle, style: text.bodySmall),
                    ],
                  ),
                ),
              ),
              PrayerReminderSwitch(
                label: title,
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One weekday toggle: a 40px circle inside a full-height 48px target. The
/// fill and letter colour animate with the standard curve (instant under
/// reduced motion).
class PrayerDayToggle extends StatelessWidget {
  const PrayerDayToggle({
    super.key,
    required this.letter,
    required this.name,
    required this.selected,
    required this.onChanged,
  });
  final String letter, name;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = selected ? colors.onSurface : colors.surfaceContainerHighest;
    final ink = selected
        ? (ThemeData.estimateBrightnessForColor(colors.onSurface) ==
                Brightness.dark
            ? Colors.white
            : Colors.black)
        : colors.onSurface;
    final duration = AppMotion.duration(context, AppMotion.control);
    final scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      onTap: () => onChanged(!selected),
      excludeSemantics: true,
      child: AppPressMotion(
        child: InkResponse(
          onTap: () => onChanged(!selected),
          customBorder: const CircleBorder(),
          radius: 24,
          child: SizedBox(
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: duration,
                curve: AppMotion.curve,
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: AppMotion.curve,
                  style: (Theme.of(context).textTheme.labelLarge ??
                          const TextStyle())
                      .copyWith(
                    color: ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    letter,
                    textScaler: scaler.scale(13) / 13 > 1.3
                        ? const TextScaler.linear(1.3)
                        : scaler,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
