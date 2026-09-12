import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import 'give_repository.dart';

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
  bool busy = false, autoGive = false;
  String? error;
  TimeOfDay chargeTime = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> weekdays = {};
  final Set<String> selectedRules = {};
  final Map<String, String> selectedLabels = {};
  int get amountKobo => (int.tryParse(digits) ?? 0) * 100;
  bool get canSubmit => !busy && amountKobo >= 10000;
  String get amountText =>
      NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2)
          .format(amountKobo / 100);

  @override
  void initState() {
    super.initState();
    repo = widget.repository ?? GiveRepository();
    events = widget.eventLoader?.call() ?? repo.schedulableEvents();
  }

  void press(String value) {
    if (value == 'back') {
      if (digits.isNotEmpty)
        setState(() => digits = digits.substring(0, digits.length - 1));
    } else if (digits.length < 9) {
      setState(() => digits = digits == '0' ? value : digits + value);
    }
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
    if (kind == 'weekly' && day != null && day >= 1 && day <= 7)
      return 'weekday:$day:$id';
    final monthDay = int.tryParse(row['day_of_month']?.toString() ?? '');
    final month = int.tryParse(row['month']?.toString() ?? '');
    if (kind == 'monthly' && monthDay != null) return 'monthly:$monthDay:$id';
    if (kind == 'yearly' && month != null && monthDay != null)
      return 'yearly:$month:$monthDay:$id';
    return 'recurring:$id';
  }

  Future<void> chooseServices() async {
    final rules = Set<String>.of(selectedRules);
    final labels = Map<String, String>.of(selectedLabels);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: WpccColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 10, 8),
                  child: Row(children: [
                    const Expanded(
                        child: Text('Service days',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600))),
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
                  child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                future: events,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError)
                    return const Center(
                        child: Text('Unable to load service days'));
                  final recurring = snapshot.data?['recurring'] ?? const [];
                  final upcoming = snapshot.data?['upcoming'] ?? const [];
                  if (recurring.isEmpty && upcoming.isEmpty)
                    return const Center(child: Text('No upcoming services'));
                  return ListView(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                      children: [
                        if (recurring.isNotEmpty)
                          const _GroupLabel('Recurring services'),
                        ...recurring.map((row) {
                          final rule = recurringRule(row);
                          final title =
                              row['title']?.toString() ?? 'Recurring service';
                          return CheckboxListTile(
                              value: rules.contains(rule),
                              onChanged: (v) => toggle(rule, title, v ?? false),
                              title: Text(title),
                              subtitle: Text(
                                  '${row['recurrence_type'] ?? 'Recurring'} · ${row['start_time'] ?? ''}'),
                              controlAffinity: ListTileControlAffinity.leading);
                        }),
                        if (upcoming.isNotEmpty)
                          const _GroupLabel('Upcoming events'),
                        ...upcoming.map((row) {
                          final rule = upcomingRule(row);
                          final title =
                              row['title']?.toString() ?? 'Upcoming event';
                          final start = DateTime.tryParse(
                              row['event_start_at']?.toString() ??
                                  row['starts_at']?.toString() ??
                                  '');
                          return CheckboxListTile(
                              value: rules.contains(rule),
                              onChanged: rule.contains('event::')
                                  ? null
                                  : (v) => toggle(rule, title, v ?? false),
                              title: Text(title),
                              subtitle: Text(start == null
                                  ? 'Upcoming'
                                  : DateFormat('EEE, d MMM · h:mm a')
                                      .format(start.toLocal())),
                              controlAffinity: ListTileControlAffinity.leading);
                        }),
                      ]);
                },
              )),
            ]));
      }),
    );
  }

  Future<void> submit() async {
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
        givingType: widget.payload['giving_type']?.toString() ?? 'offering',
        projectId: widget.payload['project_id']?.toString(),
        autoGive: autoGive
            ? {
                'rule_keys': rules,
                'local_charge_time': timeValue,
                'timezone': 'Africa/Lagos',
                'event_labels': selectedLabels
              }
            : null,
      );
      final url = Uri.tryParse(result['authorization_url']?.toString() ?? '');
      if (url == null) throw StateError('Payment link was not returned');
      if (!await launchUrl(url, webOnlyWindowName: '_self'))
        throw StateError('Unable to open Paystack');
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
              tooltip: 'Back to Give',
              onPressed: () => context.go('/give'),
              icon: Icon(PhosphorIcons.caretLeft(), size: 20)),
          title: Text(widget.payload['title']?.toString() ?? 'Give',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                          child: Column(children: [
                            const SizedBox(height: 24),
                            Text('Enter amount',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: WpccColors.muted)),
                            const SizedBox(height: 10),
                            FittedBox(
                                child: Text(amountText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -1.4))),
                            const SizedBox(height: 18),
                            _AutoGiveCard(
                                enabled: autoGive,
                                weekdays: weekdays,
                                selectedCount: selectedRules.length,
                                chargeTime: chargeTime,
                                onToggle: () =>
                                    setState(() => autoGive = !autoGive),
                                onWeekday: (day) => setState(() =>
                                    weekdays.contains(day)
                                        ? weekdays.remove(day)
                                        : weekdays.add(day)),
                                onServices: chooseServices,
                                onTime: pickTime),
                            if (error != null) ...[
                              const SizedBox(height: 10),
                              Semantics(
                                  liveRegion: true,
                                  child: Text(error!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.redAccent)))
                            ],
                            const SizedBox(height: 24),
                            _Keypad(onKey: press),
                            const SizedBox(height: 16),
                            SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  onPressed: canSubmit ? submit : null,
                                  style: FilledButton.styleFrom(
                                      backgroundColor: WpccColors.ink,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18))),
                                  child: busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('Continue'),
                                )),
                          ])),
                    )))),
      );
}

class _AutoGiveCard extends StatelessWidget {
  const _AutoGiveCard(
      {required this.enabled,
      required this.weekdays,
      required this.selectedCount,
      required this.chargeTime,
      required this.onToggle,
      required this.onWeekday,
      required this.onServices,
      required this.onTime});
  final bool enabled;
  final Set<int> weekdays;
  final int selectedCount;
  final TimeOfDay chargeTime;
  final VoidCallback onToggle, onServices, onTime;
  final ValueChanged<int> onWeekday;
  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: enabled ? WpccColors.primary : WpccColors.line)),
        child: Column(children: [
          InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(14),
              child: Row(children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: WpccColors.primarySoft,
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(PhosphorIcons.arrowsClockwise(),
                        size: 18, color: WpccColors.primaryDeep)),
                const SizedBox(width: 10),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Auto give this amount',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('Schedule future gifts after this payment',
                          style:
                              TextStyle(fontSize: 11, color: WpccColors.muted))
                    ])),
                Icon(
                    enabled
                        ? PhosphorIcons.caretUp()
                        : PhosphorIcons.caretDown(),
                    size: 18),
              ])),
          if (enabled) ...[
            const SizedBox(height: 16),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Repeat days',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
            const SizedBox(height: 8),
            Row(
                children: List.generate(
                    7,
                    (i) => Expanded(
                        child: Padding(
                            padding: EdgeInsets.only(right: i == 6 ? 0 : 4),
                            child: InkWell(
                                onTap: () => onWeekday(i + 1),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: weekdays.contains(i + 1)
                                            ? WpccColors.ink
                                            : WpccColors.subtle,
                                        borderRadius: BorderRadius.circular(12),
                                        border:
                                            Border.all(color: WpccColors.line)),
                                    child: Text(labels[i],
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: weekdays.contains(i + 1)
                                                ? Colors.white
                                                : WpccColors.ink)))))))),
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
          ],
        ]));
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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
              color: WpccColors.subtle,
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
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: WpccColors.muted))
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String> onKey;
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
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.7),
        itemBuilder: (context, i) {
          final keyValue = keys[i];
          return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onKey(keyValue),
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WpccColors.line)),
                  child: Center(
                      child: keyValue == 'back'
                          ? Icon(PhosphorIcons.backspace(), size: 20)
                          : Text(keyValue,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500)))));
        });
  }
}
