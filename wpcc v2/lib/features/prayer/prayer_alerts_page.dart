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
  @override State<PrayerAlertsPage> createState() => _PrayerAlertsPageState();
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
        SnackBar(content: Text('Prayer reminder snoozed for $minutes minutes.')),
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
        title: const Text('Prayer alerts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        actions: [IconButton(onPressed: () async { await context.push('/prayer-alerts/new'); reload(); }, icon: Icon(PhosphorIcons.plus(), size: 20))],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return SectionEmptyState(icon: PhosphorIcons.warningCircle(), message: 'Unable to load prayer alerts');
          final rows = snapshot.data ?? const [];
          final global = rows.where((a) => a['scope'] != 'personal').toList();
          final personal = rows.where((a) => a['scope'] == 'personal').toList();
          return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 40), children: [
            _PushSetupCard(
              configured: AppConfig.vapidPublicKey.isNotEmpty,
              enabled: pushEnabledThisSession,
              busy: enablingPush,
              onEnable: _enablePush,
            ),
            const SizedBox(height: 22),
            Text('Global reminders', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            if (global.isEmpty)
              SectionEmptyState(icon: PhosphorIcons.globeHemisphereWest(), message: 'No global prayer alerts', height: 110)
            else
              ...global.map((a) => _AlertRow(
                    alert: a,
                    readOnly: true,
                    onChanged: (_) {},
                    onTap: () => _start(context, a),
                    onStart: () => _start(context, a),
                    onCalendar: () => calendarService.downloadAlert(a),
                  )),
            const SizedBox(height: 24),
            Text('Personal reminders', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            if (personal.isEmpty) SectionEmptyState(icon: PhosphorIcons.bellSimple(), message: 'No personal prayer alerts', height: 130) else ...personal.map((a) => _AlertRow(
              alert: a,
              readOnly: false,
              onChanged: (value) => _setActive(a, value),
              onTap: () => context.push('/prayer-alerts/${a['id']}/edit', extra: a).then((_) => reload()),
              onStart: startingAlerts.contains(a['id']?.toString()) ? null : () => _start(context, a),
              onCalendar: () => calendarService.downloadAlert(a),
            )),
          ]);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prayer push reminders enabled.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to start prayer session. Please try again.')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update prayer alert. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => updatingAlerts.remove(id));
    }
  }
}

class _PushSetupCard extends StatelessWidget {
  const _PushSetupCard({
    required this.configured,
    required this.enabled,
    required this.busy,
    required this.onEnable,
  });

  final bool configured;
  final bool enabled;
  final bool busy;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F7),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(enabled ? PhosphorIcons.bellRinging() : PhosphorIcons.bellSimple(), size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(enabled ? 'Push reminders enabled' : 'Prayer push reminders', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(
              !configured
                  ? 'Deployment push keys are not configured yet.'
                  : enabled
                      ? 'This browser can receive server-scheduled prayer alerts.'
                      : 'Allow this browser to receive server-scheduled alerts.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: WpccColors.muted, fontSize: 11),
            ),
          ]),
        ),
        if (configured && !enabled)
          TextButton(
            onPressed: busy ? null : onEnable,
            child: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enable', style: TextStyle(fontSize: 12)),
          ),
      ]),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.readOnly, required this.onChanged, required this.onTap, this.onStart, this.onCalendar});
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
    final dt = DateTime(2000, 1, 1, int.tryParse(parts[0]) ?? 6, int.tryParse(parts[1]) ?? 0);
    final days = ((alert['days_of_week'] as List?) ?? const []).map((e) => e as int).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFF0F1F5))),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('h:mm a').format(dt), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -1)),
              const SizedBox(height: 2),
              Text(alert['title']?.toString() ?? 'Prayer', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(_daysLabel(days), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: WpccColors.muted)),
            ])),
            if (onCalendar != null) IconButton(tooltip: 'Add to calendar', onPressed: onCalendar, icon: Icon(PhosphorIcons.calendarPlus(), size: 17)),
            if (onStart != null) IconButton(onPressed: onStart, icon: Icon(PhosphorIcons.play(), size: 17)),
            if (readOnly) Icon(PhosphorIcons.lockSimple(), size: 16, color: WpccColors.muted) else Switch(value: alert['is_active'] == true, onChanged: onChanged),
          ]),
        ),
      ),
    );
  }

  static String _daysLabel(List<int> days) {
    if (days.length == 7) return 'Every day';
    const labels = {1:'Mon',2:'Tue',3:'Wed',4:'Thu',5:'Fri',6:'Sat',7:'Sun'};
    return days.map((d) => labels[d]).whereType<String>().join(', ');
  }
}
