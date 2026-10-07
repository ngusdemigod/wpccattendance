import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/member_material.dart';
import '../../core/theme/member_theme.dart';
import '../../core/widgets/member_choice.dart';
import '../../core/widgets/member_glass.dart';
import '../../core/widgets/member_reveal.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_sheet.dart';
import 'give_repository.dart';
import 'giving_backdrop.dart';

class GivePaymentPage extends StatefulWidget {
  const GivePaymentPage(
      {super.key, required this.payload, this.repository, this.eventLoader});
  final Map<String, dynamic> payload;
  final GiveRepository? repository;
  final Future<Map<String, List<Map<String, dynamic>>>> Function()? eventLoader;
  @override
  State<GivePaymentPage> createState() => _GivePaymentPageState();
}

class _GivePaymentPageState extends State<GivePaymentPage> {
  late final GiveRepository repo;
  late final Future<Map<String, List<Map<String, dynamic>>>> events;
  String digits = '';
  late String givingType;
  Map<String, dynamic>? selectedProject;
  bool busy = false, autoGive = false;
  String? error;
  TimeOfDay chargeTime = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> weekdays = {};
  final Set<String> selectedRules = {};
  final Map<String, String> selectedLabels = {};
  int get amountKobo => (int.tryParse(digits) ?? 0) * 100;
  bool get canSubmit =>
      !busy &&
      amountKobo >= 10000 &&
      (givingType != 'project' || selectedProject?['id'] != null);
  String get amountText =>
      NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2)
          .format(amountKobo / 100);

  @override
  void initState() {
    super.initState();
    repo = widget.repository ?? GiveRepository();
    givingType = widget.payload['giving_type']?.toString() ?? 'offering';
    if (widget.payload['project_id'] != null) {
      selectedProject = {
        'id': widget.payload['project_id'],
        'title': widget.payload['title'] ?? 'Church project'
      };
    }
    events = widget.eventLoader?.call() ?? repo.schedulableEvents();
    // The picker may subscribe later; retain its failure without an uncaught error.
    events.ignore();
  }

  void press(String value) {
    if (value == 'back') {
      if (digits.isNotEmpty) {
        setState(() => digits = digits.substring(0, digits.length - 1));
      }
    } else if (digits.length < 9) {
      setState(() => digits = digits == '0' ? value : digits + value);
    }
  }

  void preset(int amount) => setState(() => digits = amount.toString());

  Future<void> chooseProject(BuildContext context) async {
    var projects = repo.projects();
    final selected = await showMemberSheet<Map<String, dynamic>>(
      context: context,
      title: 'Choose a project',
      builder: (sheetContext) => StatefulBuilder(
          builder: (context, update) =>
              FutureBuilder<List<Map<String, dynamic>>>(
                future: projects,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return MemberStatus(
                        message: 'Unable to load church projects',
                        onRetry: () =>
                            update(() => projects = repo.projects()));
                  }
                  final rows = (snapshot.data ?? [])
                      .where((row) => row['id'] != null)
                      .toList();
                  if (rows.isEmpty) {
                    return const MemberStatus(
                        message: 'No active church projects');
                  }
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final project in rows)
                      MemberListRow(
                        title: project['title']?.toString() ?? 'Church project',
                        leading: Icon(PhosphorIcons.gift()),
                        trailing: Icon(
                            selectedProject?['id'] == project['id']
                                ? PhosphorIcons.check()
                                : PhosphorIcons.caretRight(),
                            size: 18),
                        onTap: () => Navigator.pop(sheetContext, project),
                      ),
                  ]);
                },
              )),
    );
    if (selected != null && mounted) setState(() => selectedProject = selected);
  }

  void selectType(BuildContext context, String type) {
    setState(() {
      givingType = type;
      error = null;
    });
    if (type == 'project' && selectedProject == null) chooseProject(context);
  }

  Widget _disclosure(BuildContext context) {
    final settings = autoGive
        ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _AutoGiveSettings(
                weekdays: weekdays,
                selectedCount: selectedRules.length,
                chargeTime: chargeTime,
                onWeekday: (day) => setState(() => weekdays.contains(day)
                    ? weekdays.remove(day)
                    : weekdays.add(day)),
                onServices: chooseServices,
                onTime: pickTime))
        : const SizedBox(width: double.infinity);
    if (MediaQuery.disableAnimationsOf(context)) return settings;
    return AnimatedSize(
        duration: AppMotion.control,
        curve: AppMotion.curve,
        alignment: Alignment.topCenter,
        child: settings);
  }

  String get timeValue =>
      '${chargeTime.hour.toString().padLeft(2, '0')}:${chargeTime.minute.toString().padLeft(2, '0')}:00';

  Future<void> pickTime() async {
    final value =
        await showTimePicker(context: context, initialTime: chargeTime);
    if (value != null && mounted) setState(() => chargeTime = value);
  }

  String upcomingRule(Map<String, dynamic> row) {
    final raw =
        row['event_start_at']?.toString() ?? row['starts_at']?.toString() ?? '';
    final date = DateTime.tryParse(raw)?.toLocal();
    return 'event:${date == null ? '' : DateFormat('yyyy-MM-dd').format(date)}:${row['event_id'] ?? row['id']}';
  }

  String recurringRule(Map<String, dynamic> row) {
    final id = row['recurring_event_id'];
    final kind = row['recurrence_type']?.toString().toLowerCase();
    final day = int.tryParse(row['day_of_week']?.toString() ?? '');
    if (kind == 'weekly' && day != null && day >= 1 && day <= 7) {
      return 'weekday:$day:$id';
    }
    final monthDay = int.tryParse(row['day_of_month']?.toString() ?? '');
    final month = int.tryParse(row['month']?.toString() ?? '');
    if (kind == 'monthly' && monthDay != null) return 'monthly:$monthDay:$id';
    if (kind == 'yearly' && month != null && monthDay != null) {
      return 'yearly:$month:$monthDay:$id';
    }
    return 'recurring:$id';
  }

  Future<void> chooseServices() async {
    final rules = Set<String>.of(selectedRules);
    final labels = Map<String, String>.of(selectedLabels);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (sheetContext) =>
          StatefulBuilder(builder: (context, setSheetState) {
        void toggle(String rule, String label, bool checked) =>
            setSheetState(() {
              if (checked) {
                rules.add(rule);
                labels[rule] = label;
              } else {
                rules.remove(rule);
                labels.remove(rule);
              }
            });
        return FractionallySizedBox(
            heightFactor: .88,
            child: MemberGlass(
                radius: 32,
                weight: MemberMaterialWeight.sheet,
                child: Material(
                    type: MaterialType.transparency,
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 10, 8),
                          child: Row(children: [
                            const Expanded(
                                child: Text('Service days',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600))),
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedRules
                                      ..clear()
                                      ..addAll(rules);
                                    selectedLabels
                                      ..clear()
                                      ..addAll(labels);
                                  });
                                  Navigator.pop(sheetContext);
                                },
                                child: const Text('Done')),
                          ])),
                      const Divider(height: 1),
                      Expanded(
                          child: FutureBuilder<
                              Map<String, List<Map<String, dynamic>>>>(
                        future: events,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Unable to load service days'));
                          }
                          final recurring =
                              snapshot.data?['recurring'] ?? const [];
                          final upcoming =
                              snapshot.data?['upcoming'] ?? const [];
                          if (recurring.isEmpty && upcoming.isEmpty) {
                            return const Center(
                                child: Text('No upcoming services'));
                          }
                          return ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 10, 12, 24),
                              children: [
                                if (recurring.isNotEmpty)
                                  const _GroupLabel('Recurring services'),
                                ...recurring.map((row) {
                                  final rule = recurringRule(row);
                                  final title = row['title']?.toString() ??
                                      'Recurring service';
                                  return CheckboxListTile(
                                      value: rules.contains(rule),
                                      onChanged: (v) =>
                                          toggle(rule, title, v ?? false),
                                      title: Text(title),
                                      subtitle: Text(
                                          '${row['recurrence_type'] ?? 'Recurring'} · ${row['start_time'] ?? ''}'),
                                      controlAffinity:
                                          ListTileControlAffinity.leading);
                                }),
                                if (upcoming.isNotEmpty)
                                  const _GroupLabel('Upcoming events'),
                                ...upcoming.map((row) {
                                  final rule = upcomingRule(row);
                                  final title = row['title']?.toString() ??
                                      'Upcoming event';
                                  final start = DateTime.tryParse(
                                      row['event_start_at']?.toString() ??
                                          row['starts_at']?.toString() ??
                                          '');
                                  return CheckboxListTile(
                                      value: rules.contains(rule),
                                      onChanged: rule.contains('event::')
                                          ? null
                                          : (v) =>
                                              toggle(rule, title, v ?? false),
                                      title: Text(title),
                                      subtitle: Text(start == null
                                          ? 'Upcoming'
                                          : DateFormat('EEE, d MMM · h:mm a')
                                              .format(start.toLocal())),
                                      controlAffinity:
                                          ListTileControlAffinity.leading);
                                }),
                              ]);
                        },
                      )),
                    ]))));
      }),
    );
  }

  Future<void> submit() async {
    if (busy) return;
    if (givingType == 'project' && selectedProject?['id'] == null) {
      setState(() => error = 'Choose a church project');
      return;
    }
    if (amountKobo < 10000) {
      setState(() => error = 'Enter an amount of at least ₦100');
      return;
    }
    if (autoGive && weekdays.isEmpty && selectedRules.isEmpty) {
      setState(() => error = 'Choose at least one day or service');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final rules = <String>[
        ...weekdays.map((d) => 'weekday:$d'),
        ...selectedRules
      ];
      final result = await repo.initialize(
        amountKobo: amountKobo,
        givingType: givingType,
        projectId: givingType == 'project'
            ? (selectedProject?['id'])?.toString()
            : null,
        appOrigin: kIsWeb ? Uri.base.origin : null,
        autoGive: autoGive
            ? {
                'rule_keys': rules,
                'local_charge_time': timeValue,
                'timezone': 'Africa/Lagos',
                'event_labels': selectedLabels
              }
            : null,
      );
      if (!mounted) return;
      final url = Uri.tryParse(result['authorization_url']?.toString() ?? '');
      if (url == null) throw StateError('Payment link was not returned');
      if (!await launchUrl(url, webOnlyWindowName: '_self')) {
        throw StateError('Unable to open Paystack');
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MemberTheme(
      child: Builder(
          builder: (context) => GivingBackdrop(
                child: Scaffold(
                  bottomNavigationBar: _dockKeypad(context)
                      ? SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: Align(
                              heightFactor: 1,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 456),
                                child: _paymentControls(context),
                              ),
                            ),
                          ),
                        )
                      : null,
                  body: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: LayoutBuilder(
                            builder: (context, viewport) =>
                                CustomScrollView(slivers: [
                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                        MediaQuery.sizeOf(context).width < 600
                                            ? 20
                                            : 32,
                                        20,
                                        MediaQuery.sizeOf(context).width < 600
                                            ? 20
                                            : 32,
                                        24),
                                    sliver: SliverToBoxAdapter(
                                      child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                              minHeight: (viewport.maxHeight -
                                                      44)
                                                  .clamp(0, double.infinity)),
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(children: [
                                                  MemberReveal(
                                                      child: Row(children: [
                                                    Expanded(
                                                        child: Text('Give',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleSmall
                                                                ?.copyWith(
                                                                    fontSize:
                                                                        17,
                                                                    height:
                                                                        1.3))),
                                                    MemberIconButton(
                                                        icon:
                                                            PhosphorIconsRegular
                                                                .caretLeft,
                                                        label: 'Back to Give',
                                                        plain: true,
                                                        onPressed: () => context
                                                            .go('/give')),
                                                  ])),
                                                  const SizedBox(height: 12),
                                                  MemberReveal(
                                                      index: 1,
                                                      child:
                                                          SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: Row(children: [
                                                          for (final type in {
                                                            'offering':
                                                                'Offerings',
                                                            'tithe': 'Tithe',
                                                            'prophet_offering':
                                                                'Prophet offering',
                                                          }.entries)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right: 8),
                                                              child:
                                                                  AppPressMotion(
                                                                      child:
                                                                          ChoiceChip(
                                                                label: Text(
                                                                    type.value),
                                                                selected:
                                                                    givingType ==
                                                                        type.key,
                                                                showCheckmark:
                                                                    false,
                                                                selectedColor: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onSurface,
                                                                labelStyle: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .labelMedium
                                                                    ?.copyWith(
                                                                      color: givingType ==
                                                                              type
                                                                                  .key
                                                                          ? Theme.of(context)
                                                                              .colorScheme
                                                                              .surfaceContainerLowest
                                                                          : Theme.of(context)
                                                                              .colorScheme
                                                                              .onSurface,
                                                                    ),
                                                                onSelected: busy
                                                                    ? null
                                                                    : (_) => selectType(
                                                                        context,
                                                                        type.key),
                                                              )),
                                                            ),
                                                        ]),
                                                      )),
                                                  if (givingType == 'project')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 8),
                                                      child: TextButton.icon(
                                                        onPressed: busy
                                                            ? null
                                                            : () =>
                                                                chooseProject(
                                                                    context),
                                                        icon: Icon(
                                                            PhosphorIcons
                                                                .caretDown(),
                                                            size: 16),
                                                        label: Text(selectedProject?[
                                                                    'title']
                                                                ?.toString() ??
                                                            'Choose a project'),
                                                      ),
                                                    ),
                                                  const SizedBox(height: 24),
                                                  MemberReveal(
                                                      index: 2,
                                                      child: Text(
                                                          'Enter amount',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall)),
                                                  const SizedBox(height: 10),
                                                  MemberReveal(
                                                      index: 2,
                                                      child: Semantics(
                                                          liveRegion: true,
                                                          child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: Text(
                                                                  amountText,
                                                                  key: const ValueKey(
                                                                      'giving-amount'),
                                                                  style: Theme
                                                                          .of(
                                                                              context)
                                                                      .textTheme
                                                                      .headlineLarge
                                                                      ?.copyWith(
                                                                          fontSize:
                                                                              48,
                                                                          height:
                                                                              1.18,
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          letterSpacing:
                                                                              0))))),
                                                  const SizedBox(height: 8),
                                                  MemberReveal(
                                                      index: 2,
                                                      child: Text(
                                                          'Minimum ₦100',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall)),
                                                  const SizedBox(height: 24),
                                                  MemberReveal(
                                                      index: 3,
                                                      child: Wrap(
                                                          spacing: 8,
                                                          runSpacing: 4,
                                                          alignment:
                                                              WrapAlignment
                                                                  .center,
                                                          children: [
                                                            for (final amount
                                                                in [
                                                              1000,
                                                              5000,
                                                              10000,
                                                              20000
                                                            ])
                                                              MemberChoice(
                                                                  label: NumberFormat.currency(
                                                                          locale:
                                                                              'en_NG',
                                                                          symbol:
                                                                              '₦',
                                                                          decimalDigits:
                                                                              0)
                                                                      .format(
                                                                          amount),
                                                                  selected:
                                                                      digits ==
                                                                          amount
                                                                              .toString(),
                                                                  minWidth: 72,
                                                                  onTap: busy
                                                                      ? null
                                                                      : () => preset(
                                                                          amount)),
                                                          ])),
                                                  const SizedBox(height: 16),
                                                  MemberReveal(
                                                      index: 4,
                                                      child: SwitchListTile
                                                          .adaptive(
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        title: const Text(
                                                            'Auto give'),
                                                        subtitle: Text(
                                                            autoGive
                                                                ? 'Repeat after this payment'
                                                                : 'Off · One-time payment',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall),
                                                        value: autoGive,
                                                        onChanged: busy
                                                            ? null
                                                            : (value) =>
                                                                setState(() {
                                                                  autoGive =
                                                                      value;
                                                                  error = null;
                                                                }),
                                                      )),
                                                  _disclosure(context),
                                                  MemberSwap(
                                                      animateSize: false,
                                                      child: error == null
                                                          ? const SizedBox(
                                                              width: double
                                                                  .infinity)
                                                          : Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 12),
                                                              child: Semantics(
                                                                  liveRegion:
                                                                      true,
                                                                  child: Text(
                                                                      error!,
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodySmall
                                                                          ?.copyWith(
                                                                              color: Theme.of(context).colorScheme.error))))),
                                                ]),
                                                if (!_dockKeypad(context))
                                                  _paymentControls(context),
                                              ])),
                                    ),
                                  ),
                                ])),
                      ),
                    ),
                  ),
                ),
              )));

  bool _dockKeypad(BuildContext context) =>
      MediaQuery.sizeOf(context).height >= 720 &&
      MediaQuery.textScalerOf(context).scale(14) <= 18.2;

  Widget _paymentControls(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16),
        _Keypad(onKey: busy ? null : press),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: AppPressMotion(
              child: FilledButton(
            onPressed: canSubmit ? submit : null,
            child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.tab),
                switchInCurve: AppMotion.curve,
                switchOutCurve: AppMotion.curve.flipped,
                child: busy
                    ? const SizedBox.square(
                        key: ValueKey('busy'),
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continue', key: ValueKey('label'))),
          )),
        ),
      ]);
}

class _AutoGiveSettings extends StatelessWidget {
  const _AutoGiveSettings(
      {required this.weekdays,
      required this.selectedCount,
      required this.chargeTime,
      required this.onWeekday,
      required this.onServices,
      required this.onTime});
  final Set<int> weekdays;
  final int selectedCount;
  final TimeOfDay chargeTime;
  final VoidCallback onServices, onTime;
  final ValueChanged<int> onWeekday;
  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return MemberGlass(
        radius: 20,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Schedule future gifts after this payment',
                      style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(height: 16),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Repeat days',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500))),
              const SizedBox(height: 8),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 4, runSpacing: 4, children: [
                    for (var i = 0; i < 7; i++)
                      Semantics(
                          selected: weekdays.contains(i + 1),
                          child: TextButton(
                              onPressed: () => onWeekday(i + 1),
                              style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  foregroundColor: weekdays.contains(i + 1)
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLowest
                                      : Theme.of(context).colorScheme.onSurface,
                                  backgroundColor: weekdays.contains(i + 1)
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                  textStyle:
                                      Theme.of(context).textTheme.labelMedium),
                              child: Text(labels[i]))),
                  ])),
              const SizedBox(height: 10),
              _ScheduleRow(
                  icon: PhosphorIcons.calendarCheck(),
                  title: 'Service days',
                  value: selectedCount == 0
                      ? 'Choose upcoming or recurring services'
                      : '$selectedCount selected',
                  onTap: onServices),
              const SizedBox(height: 8),
              _ScheduleRow(
                  icon: PhosphorIcons.clock(),
                  title: 'Charge time',
                  value: chargeTime.format(context),
                  onTap: onTime),
            ])));
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onTap});
  final IconData icon;
  final String title, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(icon, size: 18),
            const SizedBox(width: 9),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant))
                ])),
            Icon(PhosphorIcons.caretRight(), size: 16)
          ])));
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String>? onKey;
  @override
  Widget build(BuildContext context) {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '00',
      '0',
      'back'
    ];
    return Column(
      children: List.generate(
          4,
          (row) => Padding(
                padding: EdgeInsets.only(bottom: row == 3 ? 0 : 8),
                child: Row(
                  children: List.generate(3, (column) {
                    final keyValue = keys[(row * 3) + column];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: column == 2 ? 0 : 8),
                        child: Semantics(
                            button: true,
                            enabled: onKey != null,
                            label: keyValue == 'back'
                                ? 'Delete last digit'
                                : keyValue,
                            excludeSemantics: true,
                            child: AppPressMotion(
                                child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap:
                                  onKey == null ? null : () => onKey!(keyValue),
                              child: Container(
                                height:
                                    MediaQuery.textScalerOf(context).scale(26) +
                                                24 <
                                            58
                                        ? 58
                                        : MediaQuery.textScalerOf(context)
                                                .scale(26) +
                                            24,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: keyValue == 'back'
                                      ? Icon(PhosphorIcons.backspace(),
                                          size: 22)
                                      : Text(keyValue,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ))),
                      ),
                    );
                  }),
                ),
              )),
    );
  }
}
