import 'dart:async';

import 'package:flutter/material.dart';

import 'prayer_alerts_content.dart';

/// Loads the alerts and owns the optimistic switch state for
/// [PrayerAlertsContent]. It has no browser dependencies, so it is testable
/// without Web Push or calendar services; the page supplies those as callbacks.
class PrayerAlertsView extends StatefulWidget {
  const PrayerAlertsView({
    super.key,
    required this.loadAlerts,
    required this.setActive,
    required this.onTap,
    required this.onStart,
    required this.onCalendar,
    required this.onAdd,
    this.onBack,
    this.starting = const {},
    this.onEnablePush,
    this.enablingPush = false,
  });

  final Future<List<Map<String, dynamic>>> Function() loadAlerts;
  final Future<void> Function(
      String id, bool active, Map<String, dynamic> alert) setActive;

  /// Opens the editor for a personal alert or starts a church alert. The
  /// list reloads when the returned future completes.
  final Future<void> Function(Map<String, dynamic> alert) onTap;
  final ValueChanged<Map<String, dynamic>> onStart, onCalendar;

  /// Opens the new-alert editor. The list reloads when it completes.
  final Future<void> Function() onAdd;
  final VoidCallback? onBack, onEnablePush;
  final Set<String> starting;
  final bool enablingPush;

  @override
  State<PrayerAlertsView> createState() => _PrayerAlertsViewState();
}

class _PrayerAlertsViewState extends State<PrayerAlertsView> {
  List<Map<String, dynamic>>? alerts;
  bool loading = true;
  Object? loadError;
  int generation = 0;

  /// Switch values shown immediately while the save is in flight.
  final Map<String, bool> optimistic = {};
  final Set<String> updating = {};

  @override
  void initState() {
    super.initState();
    _fetch(++generation);
  }

  /// The list stays on screen while it refreshes; the skeleton shows only
  /// until the first result. A refresh that follows a successful toggle never
  /// replaces the list with an error.
  Future<void> _load({bool quiet = false}) {
    final run = ++generation;
    if (!quiet) {
      setState(() {
        loading = alerts == null;
        loadError = null;
      });
    }
    return _fetch(run, quiet: quiet);
  }

  Future<void> _fetch(int run, {bool quiet = false}) async {
    try {
      final rows = await widget.loadAlerts();
      if (!mounted || run != generation) return;
      setState(() {
        alerts = rows;
        loading = false;
        loadError = null;
      });
    } catch (error) {
      if (!mounted || run != generation || quiet) return;
      setState(() {
        loading = false;
        loadError = error;
      });
    }
  }

  Future<void> _setActive(Map<String, dynamic> alert, bool value) async {
    final id = alert['id'].toString();
    if (updating.contains(id)) return;
    setState(() {
      updating.add(id);
      optimistic[id] = value;
    });
    try {
      await widget.setActive(id, value, alert);
      if (mounted) {
        // Keep the saved value on screen even if the refresh below fails.
        setState(() => alerts = [
              for (final row in alerts ?? const <Map<String, dynamic>>[])
                row['id']?.toString() == id
                    ? {...row, 'is_active': value}
                    : row,
            ]);
        unawaited(_load(quiet: true));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update prayer alert. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          updating.remove(id);
          optimistic.remove(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final alert in alerts ?? const <Map<String, dynamic>>[])
        optimistic.containsKey(alert['id']?.toString())
            ? {...alert, 'is_active': optimistic[alert['id'].toString()]}
            : alert,
    ];
    return PrayerAlertsContent(
      onBack: widget.onBack,
      loading: loading,
      alerts: shown,
      error:
          loadError != null && !loading ? 'Unable to load prayer alerts' : null,
      onRefresh: () => _load(),
      onAdd: () async {
        await widget.onAdd();
        if (mounted) unawaited(_load());
      },
      onTap: (alert) async {
        await widget.onTap(alert);
        if (mounted && alert['scope'] == 'personal') unawaited(_load());
      },
      onStart: widget.onStart,
      onCalendar: widget.onCalendar,
      onToggle: _setActive,
      updating: updating,
      starting: widget.starting,
      onEnablePush: widget.onEnablePush,
      enablingPush: widget.enablingPush,
    );
  }
}
