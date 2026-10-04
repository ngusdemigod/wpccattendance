import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'prayer_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (loadError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loadError!),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    loading = true;
                    loadError = null;
                  });
                  _loadAlert();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.alertId == null && alert == null
              ? 'New prayer alert'
              : 'Edit prayer alert',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: WpccColors.primaryDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Prayer alert time',
            value: time.format(context),
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () async {
                final next = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (next != null) setState(() => time = next);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time.format(context),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -2,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        PhosphorIcons.clock(),
                        size: 42,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 18),
          Text(
            'Repeat',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (index) {
              final day = index + 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: index == 0 || index == 6 ? 0 : 3,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ChoiceChip(
                      selected: days.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            days.add(day);
                          } else {
                            days.remove(day);
                          }
                        });
                      },
                      showCheckmark: false,
                      selectedColor: Theme.of(context).colorScheme.onSurface,
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(labels[index], textAlign: TextAlign.center),
                      ),
                      labelPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: days.contains(day)
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      side: BorderSide.none,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Prayer duration',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              hasDuration
                  ? '${durationMinutes.round()} minutes · countdown'
                  : 'No duration · count up',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            value: hasDuration,
            onChanged: (value) => setState(() => hasDuration = value),
          ),
          if (hasDuration)
            Slider(
              min: 5,
              max: 120,
              divisions: 23,
              value: durationMinutes.clamp(5, 120),
              label: '${durationMinutes.round()} min',
              onChanged: (value) => setState(() => durationMinutes = value),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Vibration',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Used by supported installed PWA/browser notifications',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            value: vibrationEnabled,
            onChanged: (value) => setState(() => vibrationEnabled = value),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int?>(
            initialValue: snoozeMinutes,
            decoration: const InputDecoration(labelText: 'Snooze'),
            items: const [
              DropdownMenuItem<int?>(value: null, child: Text('Off')),
              DropdownMenuItem<int?>(value: 5, child: Text('5 minutes')),
              DropdownMenuItem<int?>(value: 10, child: Text('10 minutes')),
              DropdownMenuItem<int?>(value: 15, child: Text('15 minutes')),
              DropdownMenuItem<int?>(value: 30, child: Text('30 minutes')),
            ],
            onChanged: (value) => setState(() => snoozeMinutes = value),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sound / playlist',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Text(
                  alert?['audio_title']?.toString() ??
                      'No published prayer audio selected',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: saving
                  ? null
                  : () => _show(
                        'Save this alert first, then open it from Prayer alerts to test the full session.',
                      ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(PhosphorIcons.speakerHigh(), size: 18),
              label: const Text('Test prayer alert'),
            ),
          ),
        ],
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
