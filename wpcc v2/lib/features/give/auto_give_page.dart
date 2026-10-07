import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_back.dart';
import '../../core/widgets/member_choice.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_reveal.dart';
import '../../core/widgets/member_sheet.dart';
import '../../core/widgets/member_skeleton.dart';
import 'give_repository.dart';
import 'schedule_widgets.dart';

/// Scheduled giving: a summary, the member's schedules as a list, and a
/// "New schedule" sheet. Data and mutations go through [GiveRepository]
/// exactly as before (list mandates, create mandate, cancel mandate).
class AutoGivePage extends StatefulWidget {
  const AutoGivePage({super.key, this.payload = const {}, this.repository});
  final Map<String, dynamic> payload;
  final GiveRepository? repository;
  @override
  State<AutoGivePage> createState() => _AutoGivePageState();
}

class _AutoGivePageState extends State<AutoGivePage> {
  late final repo = widget.repository ?? GiveRepository();
  final cancelling = <String>{};
  List<GiveSchedule>? schedules;
  Object? error;
  bool loading = true;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
    // A prefilled amount or type (from the payment page) opens the form.
    final amount =
        int.tryParse(widget.payload['amount_naira']?.toString() ?? '') ?? 0;
    if (amount > 0 || widget.payload['giving_type'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _newSchedule();
      });
    }
  }

  Future<void> _fetch() async {
    final current = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await repo.mandates();
      if (!mounted || current != generation) return;
      setState(() => schedules = rows.map(GiveSchedule.new).toList());
    } catch (e) {
      if (mounted && current == generation) setState(() => error = e);
    } finally {
      if (mounted && current == generation) setState(() => loading = false);
    }
  }

  Future<void> _refresh() => _fetch();

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _newSchedule() async {
    final created = await showMemberSheet<bool>(
      context: context,
      title: 'New schedule',
      builder: (sheetContext) => _NewScheduleForm(
        repo: repo,
        initialAmount:
            int.tryParse(widget.payload['amount_naira']?.toString() ?? '') ?? 0,
        initialType: widget.payload['giving_type']?.toString(),
        onAddPaymentMethod: () {
          Navigator.pop(sheetContext);
          context.push('/give/payment', extra: {
            'giving_type': 'offering',
            'title': 'Add payment method',
          });
        },
      ),
    );
    if (created == true && mounted) {
      _fetch();
      _snack('Auto Give is active');
    }
  }

  Future<void> _details(GiveSchedule schedule) => showMemberSheet<void>(
        context: context,
        title: 'Schedule details',
        builder: (sheetContext) => _ScheduleDetails(
            schedule: schedule,
            onCancel: () {
              Navigator.pop(sheetContext);
              _cancel(schedule);
            }),
      );

  Future<void> _cancel(GiveSchedule schedule) async {
    final id = schedule.id;
    if (id == null || cancelling.contains(id)) return;
    final confirmed = await showMotionDialog<bool>(
      animationStyle: AppMotion.dialogStyle(context),
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Auto Give?'),
        content: Text(
          'Future automatic gifts of ${schedule.amount} on this schedule will stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep active'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Auto Give'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => cancelling.add(id));
    try {
      await repo.cancelMandate(id);
      if (mounted) {
        _fetch();
        _snack('Auto Give cancelled');
      }
    } catch (_) {
      if (mounted) _snack('Unable to cancel Auto Give. Please try again.');
    } finally {
      if (mounted) setState(() => cancelling.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = MediaQuery.sizeOf(context).width < 600 ? 20.0 : 32.0;
    return Scaffold(
      appBar: MemberAppBar(
        title: Text('Scheduled giving',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 40),
                children: [
                  MemberReveal(child: MemberSwap(child: _summary())),
                  const SizedBox(height: 12),
                  MemberReveal(
                    index: 1,
                    child: AppPressMotion(
                      child: FilledButton.icon(
                        onPressed: _newSchedule,
                        icon: Icon(PhosphorIcons.plus(), size: 20),
                        label: const Text('New schedule'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  MemberSwap(child: _list()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    final rows = schedules;
    if (rows == null) {
      return const SizedBox(
          key: ValueKey('summary-loading'),
          height: 112,
          child: Align(
              alignment: Alignment.topLeft,
              child: MemberSkeleton(rows: 2, label: 'Loading summary')));
    }
    return ScheduleSummary(key: const ValueKey('summary'), schedules: rows);
  }

  Widget _list() {
    final rows = schedules;
    if (rows == null && loading) {
      return const MemberSkeleton(
          key: ValueKey('loading'), rows: 4, label: 'Loading schedules');
    }
    if (rows == null) {
      return MemberStatus(
          key: const ValueKey('error'),
          icon: PhosphorIcons.warningCircle(),
          message: 'Unable to load Auto Give schedules',
          onRetry: _fetch);
    }
    if (rows.isEmpty) {
      return MemberStatus(
          key: const ValueKey('empty'),
          icon: PhosphorIcons.arrowsClockwise(),
          message: 'No recurring giving setup');
    }
    final active = rows.where((s) => s.active).toList();
    final past = rows.where((s) => !s.active).toList();
    return Column(
        key: const ValueKey('list'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MemberStatus(
                    icon: PhosphorIcons.warningCircle(),
                    message: 'Unable to refresh schedules',
                    onRetry: _fetch)),
          if (active.isNotEmpty) _group('Active', active),
          if (active.isNotEmpty && past.isNotEmpty) const SizedBox(height: 28),
          if (past.isNotEmpty) _group('Past', past),
        ]);
  }

  Widget _group(String title, List<GiveSchedule> items) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium))),
      DecoratedBox(
        decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              for (var i = 0; i < items.length; i++)
                ScheduleRow(
                  schedule: items[i],
                  divider: i < items.length - 1,
                  statusOverride:
                      cancelling.contains(items[i].id) ? 'Cancelling…' : null,
                  onTap: () => _details(items[i]),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _ScheduleDetails extends StatelessWidget {
  const _ScheduleDetails({required this.schedule, required this.onCancel});
  final GiveSchedule schedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = schedule.nextCharge;
    final last = schedule.lastCharge;
    final started = schedule.startedAt;
    final cancelled = schedule.cancelledAt;
    final raw = schedule.raw;
    final time = raw['local_charge_time']?.toString();
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(schedule.amount, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('${schedule.purpose} · ${schedule.statusLabel}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          _detail(context, 'Repeats', schedule.repeats),
          if (schedule.active)
            _detail(
                context,
                'Next charge',
                next == null
                    ? 'Not available'
                    : GiveSchedule.formatDateTime(next)),
          if (time != null && time.length >= 5)
            _detail(context, 'Charge time', '${time.substring(0, 5)} (Lagos)'),
          if (last != null)
            _detail(context, 'Last charge', GiveSchedule.formatDateTime(last)),
          if (started != null)
            _detail(context, 'Started', GiveSchedule.formatDate(started)),
          if (cancelled != null)
            _detail(context, 'Cancelled', GiveSchedule.formatDate(cancelled)),
          if (schedule.active) ...[
            const SizedBox(height: 20),
            AppPressMotion(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: .5))),
                child: const Text('Cancel schedule'),
              ),
            ),
          ],
        ]);
  }

  Widget _detail(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              flex: 2,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(width: 12),
          Expanded(
              flex: 3,
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500))),
        ]),
      );
}

/// The create form, unchanged in fields and validation: amount of at least
/// 100 naira, at least one event day, a saved payment source and consent.
class _NewScheduleForm extends StatefulWidget {
  const _NewScheduleForm(
      {required this.repo,
      required this.initialAmount,
      required this.initialType,
      required this.onAddPaymentMethod});
  final GiveRepository repo;
  final int initialAmount;
  final String? initialType;
  final VoidCallback onAddPaymentMethod;
  @override
  State<_NewScheduleForm> createState() => _NewScheduleFormState();
}

class _NewScheduleFormState extends State<_NewScheduleForm> {
  final amount = TextEditingController();
  final selected = <String>{};
  late Future<List<Map<String, dynamic>>> methods =
      widget.repo.savedPaymentMethods();
  String? methodId, error;
  bool consent = false, busy = false;
  String givingType = 'offering';

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount > 0) amount.text = widget.initialAmount.toString();
    if (const {'offering', 'tithe', 'prophet_offering'}
        .contains(widget.initialType)) {
      givingType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final naira =
        int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (naira < 100 || selected.isEmpty || methodId == null || !consent) {
      setState(() =>
          error = 'Complete amount, event days, payment source and consent.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.createMandate(
        amountKobo: naira * 100,
        givingType: givingType,
        ruleKeys: selected.toList(),
        authorizationId: methodId!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Unable to activate Auto Give. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Charges run securely from your saved Paystack authorization on the selected service days.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (₦)',
              hintText: '5000',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: givingType,
            decoration: const InputDecoration(labelText: 'Giving type'),
            items: const [
              DropdownMenuItem(value: 'offering', child: Text('Offering')),
              DropdownMenuItem(value: 'tithe', child: Text('Tithe')),
              DropdownMenuItem(
                value: 'prophet_offering',
                child: Text('Prophet offering'),
              ),
            ],
            onChanged: (v) => setState(() => givingType = v ?? 'offering'),
          ),
          const SizedBox(height: 20),
          Text('Event days', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 0, children: [
            for (final rule in const [
              ('sunday_service', 'Sunday Service'),
              ('wednesday', 'Wednesday'),
              ('thursday', 'Thursday'),
              ('special', 'Special'),
            ])
              MemberChoice(
                label: rule.$2,
                selected: selected.contains(rule.$1),
                onTap: () => setState(() => selected.contains(rule.$1)
                    ? selected.remove(rule.$1)
                    : selected.add(rule.$1)),
              ),
          ]),
          const SizedBox(height: 16),
          Text('Payment source', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: methods,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const MemberSkeleton(
                    rows: 2, label: 'Loading payment methods');
              }
              if (snapshot.hasError) {
                return MemberStatus(
                    icon: PhosphorIcons.warningCircle(),
                    message: 'Unable to load payment methods',
                    onRetry: () => setState(
                        () => methods = widget.repo.savedPaymentMethods()));
              }
              final rows = snapshot.data ?? const [];
              if (rows.isEmpty) {
                return Column(children: [
                  MemberStatus(
                      icon: PhosphorIcons.creditCard(),
                      message: 'No reusable Paystack payment method yet'),
                  TextButton(
                    onPressed: widget.onAddPaymentMethod,
                    child: const Text('Make a secure gift first'),
                  ),
                ]);
              }
              return RadioGroup<String>(
                groupValue: methodId,
                onChanged: (value) => setState(() => methodId = value),
                child: Column(
                  children: rows
                      .map(
                        (method) => RadioListTile<String>(
                          value: method['id'].toString(),
                          title: Text(
                            '${method['bank'] ?? method['card_type'] ?? 'Card'} •••• ${method['last4'] ?? ''}',
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            '${method['card_type'] ?? ''} ${method['exp_month'] ?? ''}/${method['exp_year'] ?? ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: consent,
            onChanged: (v) => setState(() => consent = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'I authorize WPCC to charge this saved Paystack authorization according to the selected recurring rules.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          MemberExpand(
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(error!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error)),
                    )),
          ),
          const SizedBox(height: 16),
          AppPressMotion(
            child: FilledButton(
              onPressed: busy ? null : save,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.tab),
                switchInCurve: AppMotion.curve,
                switchOutCurve: AppMotion.curve.flipped,
                child: busy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Activate schedule', key: ValueKey('label')),
              ),
            ),
          ),
        ]);
  }
}
