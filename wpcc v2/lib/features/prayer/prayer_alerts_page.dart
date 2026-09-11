import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_empty_state.dart';
import 'prayer_repository.dart';
import 'prayer_calendar_service.dart';
import 'push_subscription_service.dart';

class PrayerAlertsPage extends StatefulWidget {
  const PrayerAlertsPage({super.key});
  @override
  State<PrayerAlertsPage> createState() => _PrayerAlertsPageState();
}

class _PrayerAlertsPageState extends State<PrayerAlertsPage> {
  final repo = PrayerRepository();
  final pushService = PushSubscriptionService();
  final calendarService = const PrayerCalendarService();
  late Future<List<Map<String, dynamic>>> future = repo.alerts();
  bool enablingPush = false;
  bool pushEnabledThisSession = false;
  bool snoozeHandled = false;
  final Set<String> updatingAlerts = {};
  final Set<String> startingAlerts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleSnoozeAction());
  }

  Future<void> _handleSnoozeAction() async {
    if (snoozeHandled) return;
    snoozeHandled = true;
    final params = Uri.base.queryParameters;
    final occurrenceId = params['snooze_occurrence'];
    final minutes = int.tryParse(params['snooze_minutes'] ?? '');
    if (occurrenceId == null || minutes == null) return;
    try {
      await repo.snoozeOccurrence(occurrenceId, minutes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prayer reminder snoozed for $minutes minutes.'),
        ),
      );
      context.go('/prayer-alerts');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to snooze reminder: $error')),
      );
      context.go('/prayer-alerts');
    }
  }

  void reload() => setState(() => future = repo.alerts());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Prayer alerts',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Add prayer alert',
            onPressed: () async {
              await context.push('/prayer-alerts/new');
              reload();
            },
            icon: Icon(PhosphorIcons.plus(), size: 20),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionEmptyState(
              icon: PhosphorIcons.warningCircle(),
              message: 'Unable to load prayer alerts',
            );
          }
          final rows = snapshot.data ?? const [];
          final global = rows.where((a) => a['scope'] != 'personal').toList();
          final personal = rows.where((a) => a['scope'] == 'personal').toList();
          return RefreshIndicator(
            onRefresh: () async {
              reload();
              await future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(19, 4, 19, 110),
              children: [
                Text(
                  'Prayer alerts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prayer reminders and church-wide prayer alerts.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: WpccColors.inkSoft),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Church prayer alerts',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const Text(
                      'Admin managed',
                      style: TextStyle(fontSize: 12, color: WpccColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (global.isEmpty)
                  SectionEmptyState(
                    icon: PhosphorIcons.globeHemisphereWest(),
                    message: 'No global prayer alerts',
                    height: 110,
                  )
                else
                  ...global.map(
                    (a) => _AlertRow(
                      alert: a,
                      readOnly: true,
                      onChanged: (_) {},
                      onTap: () => _start(context, a),
                      onStart: () => _start(context, a),
                      onCalendar: () => calendarService.downloadAlert(a),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My prayer alerts',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await context.push('/prayer-alerts/new');
                        reload();
                      },
                      child: const Text(
                        'Edit',
                        style: TextStyle(fontSize: 12, color: WpccColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (personal.isEmpty)
                  SectionEmptyState(
                    icon: PhosphorIcons.bellSimple(),
                    message: 'No personal prayer alerts',
                    height: 130,
                  )
                else
                  ...personal.map(
                    (a) => _AlertRow(
                      alert: a,
                      readOnly: false,
                      onChanged: (value) => _setActive(a, value),
                      onTap: () => context
                          .push('/prayer-alerts/${a['id']}/edit', extra: a)
                          .then((_) => reload()),
                      onStart: startingAlerts.contains(a['id']?.toString())
                          ? null
                          : () => _start(context, a),
                      onCalendar: () => calendarService.downloadAlert(a),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.info(),
                      size: 15,
                      color: WpccColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Personal alerts use the sound you choose. Global alerts use the song selected by the church administrator.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: WpccColors.muted,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
                if (AppConfig.vapidPublicKey.isNotEmpty &&
                    !pushEnabledThisSession) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: enablingPush ? null : _enablePush,
                    icon: enablingPush
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(PhosphorIcons.bellRinging(), size: 16),
                    label: const Text('Enable push reminders'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _enablePush() async {
    if (enablingPush) return;
    setState(() => enablingPush = true);
    try {
      final supported = await pushService.isSupported();
      if (!supported) {
        throw StateError('This browser does not support Web Push.');
      }
      await pushService.enable(vapidPublicKey: AppConfig.vapidPublicKey);
      if (!mounted) return;
      setState(() => pushEnabledThisSession = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prayer push reminders enabled.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => enablingPush = false);
    }
  }

  Future<void> _start(BuildContext context, Map<String, dynamic> a) async {
    final id = a['id'].toString();
    if (startingAlerts.contains(id)) return;
    setState(() => startingAlerts.add(id));
    try {
      final session = await repo.startSession(alertId: id);
      if (!context.mounted) return;
      context.push('/prayer-session', extra: {'alert': a, 'session': session});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start prayer session. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => startingAlerts.remove(id));
    }
  }

  Future<void> _setActive(Map<String, dynamic> alert, bool value) async {
    final id = alert['id'].toString();
    if (updatingAlerts.contains(id)) return;
    setState(() => updatingAlerts.add(id));
    try {
      await repo.setActive(id, value, alert);
      reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update prayer alert. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => updatingAlerts.remove(id));
    }
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.readOnly,
    required this.onChanged,
    required this.onTap,
    this.onStart,
    this.onCalendar,
  });
  final Map<String, dynamic> alert;
  final bool readOnly;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTap;
  final VoidCallback? onStart;
  final VoidCallback? onCalendar;

  @override
  Widget build(BuildContext context) {
    final raw = alert['local_time']?.toString() ?? '06:00:00';
    final parts = raw.split(':');
    final dt = DateTime(
      2000,
      1,
      1,
      int.tryParse(parts[0]) ?? 6,
      int.tryParse(parts[1]) ?? 0,
    );
    final days = ((alert['days_of_week'] as List?) ?? const [])
        .map((e) => e as int)
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: DateFormat('h:mm').format(dt),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -1.6,
                            ),
                          ),
                          TextSpan(
                            text: ' ${DateFormat('a').format(dt)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: WpccColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert['title']?.toString() ?? 'Prayer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_daysLabel(days)} · ${alert['audio_title']?.toString().trim().isNotEmpty == true ? alert['audio_title'] : 'Prayer audio'}${alert['duration_seconds'] == null ? ' · Count up' : ' · ${(alert['duration_seconds'] as num).toInt() ~/ 60} min'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: WpccColors.muted),
                    ),
                  ],
                ),
              ),
              if (readOnly)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EFF8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Global',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6F329C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Switch(value: alert['is_active'] == true, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }

  static String _daysLabel(List<int> days) {
    if (days.length == 7) return 'Every day';
    const labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return days.map((d) => labels[d]).whereType<String>().join(', ');
  }
}
