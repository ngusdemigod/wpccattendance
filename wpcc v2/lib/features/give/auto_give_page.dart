import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_empty_state.dart';
import 'give_repository.dart';

class AutoGivePage extends StatefulWidget {
  const AutoGivePage({super.key});
  @override
  State<AutoGivePage> createState() => _AutoGivePageState();
}

class _AutoGivePageState extends State<AutoGivePage> {
  final repo = GiveRepository();
  final amount = TextEditingController();
  final selected = <String>{};
  final cancelling = <String>{};
  late Future<List<Map<String, dynamic>>> methods;
  late Future<List<Map<String, dynamic>>> mandates;
  String? methodId;
  bool consent = false, busy = false;
  String givingType = 'offering';
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    methods = repo.savedPaymentMethods();
    mandates = repo.mandates();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Complete amount, event days, payment source and consent.')));
      return;
    }
    setState(() => busy = true);
    try {
      await repo.createMandate(
          amountKobo: naira * 100,
          givingType: givingType,
          ruleKeys: selected.toList(),
          authorizationId: methodId!);
      if (mounted) {
        setState(_load);
        amount.clear();
        selected.clear();
        consent = false;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Auto Give is active')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to activate Auto Give. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _cancel(Map<String, dynamic> mandate) async {
    final id = mandate['id']?.toString();
    if (id == null || cancelling.contains(id)) return;
    final amountText = NumberFormat.currency(
            locale: 'en_NG', symbol: '₦', decimalDigits: 0)
        .format((int.tryParse(mandate['amount_kobo'].toString()) ?? 0) / 100);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Cancel Auto Give?'),
                content: Text(
                    'Future automatic gifts of $amountText on this schedule will stop.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep active')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cancel Auto Give'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => cancelling.add(id));
    try {
      await repo.cancelMandate(id);
      if (mounted) {
        setState(_load);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Auto Give cancelled')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to cancel Auto Give. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => cancelling.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(PhosphorIcons.caretLeft(), size: 20)),
          title: const Text('Auto give',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      body: SafeArea(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
            Text('Set up recurring giving',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600, letterSpacing: -.6)),
            const SizedBox(height: 6),
            Text(
                'Charges run securely from your saved Paystack authorization on the selected service days.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: WpccColors.muted)),
            const SizedBox(height: 22),
            TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Amount (₦)', hintText: '5000')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
                initialValue: givingType,
                decoration: const InputDecoration(labelText: 'Giving type'),
                items: const [
                  DropdownMenuItem(value: 'offering', child: Text('Offering')),
                  DropdownMenuItem(value: 'tithe', child: Text('Tithe')),
                  DropdownMenuItem(
                      value: 'prophet_offering',
                      child: Text('Prophet offering'))
                ],
                onChanged: (v) => setState(() => givingType = v ?? 'offering')),
            const SizedBox(height: 18),
            const Text('Event days',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 9),
            Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ('sunday_service', 'Sunday Service'),
                  ('wednesday', 'Wednesday'),
                  ('thursday', 'Thursday'),
                  ('special', 'Special')
                ]
                    .map((rule) => FilterChip(
                        label: Text(rule.$2),
                        selected: selected.contains(rule.$1),
                        showCheckmark: false,
                        onSelected: (value) => setState(() => value
                            ? selected.add(rule.$1)
                            : selected.remove(rule.$1)),
                        selectedColor: WpccColors.ink,
                        labelStyle: TextStyle(
                            fontSize: 11,
                            color: selected.contains(rule.$1)
                                ? Colors.white
                                : WpccColors.inkSoft),
                        backgroundColor: Colors.white,
                        side: BorderSide.none))
                    .toList()),
            const SizedBox(height: 20),
            const Text('Payment source',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 9),
            FutureBuilder<List<Map<String, dynamic>>>(
                future: methods,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return SectionEmptyState(
                        icon: PhosphorIcons.warningCircle(),
                        message: 'Unable to load payment methods');
                  }
                  final rows = snapshot.data ?? const [];
                  if (rows.isEmpty) {
                    return Column(children: [
                      SectionEmptyState(
                          icon: PhosphorIcons.creditCard(),
                          message: 'No reusable Paystack payment method yet',
                          height: 110),
                      TextButton(
                          onPressed: () => context.push('/give/payment',
                                  extra: {
                                    'giving_type': 'offering',
                                    'title': 'Add payment method'
                                  }),
                          child: const Text('Make a secure gift first'))
                    ]);
                  }
                  return RadioGroup<String>(
                      groupValue: methodId,
                      onChanged: (value) => setState(() => methodId = value),
                      child: Column(
                          children: rows
                              .map((method) => RadioListTile<String>(
                                  value: method['id'].toString(),
                                  title: Text(
                                      '${method['bank'] ?? method['card_type'] ?? 'Card'} •••• ${method['last4'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Text(
                                      '${method['card_type'] ?? ''} ${method['exp_month'] ?? ''}/${method['exp_year'] ?? ''}',
                                      style: const TextStyle(fontSize: 10)),
                                  contentPadding: EdgeInsets.zero))
                              .toList()));
                }),
            const SizedBox(height: 10),
            CheckboxListTile(
                value: consent,
                onChanged: (v) => setState(() => consent = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                    'I authorize WPCC to charge this saved Paystack authorization according to the selected recurring rules.',
                    style: TextStyle(fontSize: 11))),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: busy ? null : save,
                style: FilledButton.styleFrom(
                    backgroundColor: WpccColors.ink,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18))),
                child: busy
                    ? const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)
                    : const Text('Activate Auto Give')),
            const SizedBox(height: 28),
            const Text('Your Auto Give',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 9),
            FutureBuilder<List<Map<String, dynamic>>>(
                future: mandates,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (s.hasError) {
                    return SectionEmptyState(
                        icon: PhosphorIcons.warningCircle(),
                        message: 'Unable to load Auto Give schedules');
                  }
                  final rows = s.data ?? const [];
                  if (rows.isEmpty) {
                    return SectionEmptyState(
                        icon: PhosphorIcons.arrowsClockwise(),
                        message: 'No recurring giving setup');
                  }
                  return Column(
                      children: rows.map((m) {
                    final id = m['id']?.toString() ?? '';
                    final isCancelling = cancelling.contains(id);
                    return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          Icon(PhosphorIcons.arrowsClockwise(), size: 19),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    NumberFormat.currency(
                                            locale: 'en_NG',
                                            symbol: '₦',
                                            decimalDigits: 0)
                                        .format((int.tryParse(m['amount_kobo']
                                                    .toString()) ??
                                                0) /
                                            100),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    ((m['rule_keys'] as List?) ?? [])
                                        .map((value) => value
                                            .toString()
                                            .replaceAll('_', ' '))
                                        .join(' · '),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontSize: 10,
                                            color: WpccColors.muted))
                              ])),
                          if (m['status'] == 'active')
                            TextButton(
                                onPressed:
                                    isCancelling ? null : () => _cancel(m),
                                style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 48)),
                                child: isCancelling
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Text('Cancel',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12)))
                          else
                            Text(m['status'].toString(),
                                style: const TextStyle(fontSize: 10))
                        ]));
                  }).toList());
                }),
          ])));
}
