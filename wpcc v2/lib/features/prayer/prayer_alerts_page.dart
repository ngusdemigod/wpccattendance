import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import 'prayer_repository.dart';
import 'prayer_alerts_content.dart';
import 'prayer_calendar_service.dart';
import 'push_subscription_service.dart';

class PrayerAlertsPage extends StatefulWidget {
  const PrayerAlertsPage({super.key, this.loadAlerts});
  final Future<List<Map<String, dynamic>>> Function()? loadAlerts;
  @override
  State<PrayerAlertsPage> createState() => _PrayerAlertsPageState();
}

class _PrayerAlertsPageState extends State<PrayerAlertsPage> {
  late final repo = PrayerRepository();
  final pushService = PushSubscriptionService();
  final calendarService = const PrayerCalendarService();
  late Future<List<Map<String, dynamic>>> future =
      (widget.loadAlerts ?? repo.alerts)();
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

  void reload() => setState(() {
        future = (widget.loadAlerts ?? repo.alerts)();
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            return PrayerAlertsContent(
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
              loading: snapshot.connectionState != ConnectionState.done,
              onAdd: () async {
                await context.push('/prayer-alerts/new');
                if (mounted) reload();
              },
              alerts: snapshot.data ?? const [],
              error: snapshot.hasError ? 'Unable to load prayer alerts' : null,
              onRefresh: () async {
                reload();
                try {
                  await future;
                } catch (_) {}
              },
              onTap: (alert) {
                if (alert['scope'] != 'personal') {
                  _start(context, alert);
                } else {
                  context
                      .push('/prayer-alerts/${alert['id']}/edit', extra: alert)
                      .then((_) {
                    if (mounted) reload();
                  });
                }
              },
              onStart: (alert) => _start(context, alert),
              onCalendar: calendarService.downloadAlert,
              onToggle: _setActive,
              updating: updatingAlerts,
              starting: startingAlerts,
              onEnablePush:
                  AppConfig.vapidPublicKey.isNotEmpty && !pushEnabledThisSession
                      ? _enablePush
                      : null,
              enablingPush: enablingPush,
            );
          },
        ),
      );

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
