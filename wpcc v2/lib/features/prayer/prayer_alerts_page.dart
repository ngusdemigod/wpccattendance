import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import 'prayer_repository.dart';
import 'prayer_alerts_view.dart';
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
  bool enablingPush = false;
  bool pushEnabledThisSession = false;
  bool snoozeHandled = false;
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

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PrayerAlertsView(
          onBack: () => context.canPop() ? context.pop() : context.go('/home'),
          loadAlerts: widget.loadAlerts ?? repo.alerts,
          setActive: repo.setActive,
          onAdd: () async {
            await context.push('/prayer-alerts/new');
          },
          onTap: (alert) async {
            if (alert['scope'] != 'personal') {
              await _start(context, alert);
            } else {
              await context.push('/prayer-alerts/${alert['id']}/edit',
                  extra: alert);
            }
          },
          onStart: (alert) => _start(context, alert),
          onCalendar: calendarService.downloadAlert,
          starting: startingAlerts,
          onEnablePush:
              AppConfig.vapidPublicKey.isNotEmpty && !pushEnabledThisSession
                  ? _enablePush
                  : null,
          enablingPush: enablingPush,
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
}
