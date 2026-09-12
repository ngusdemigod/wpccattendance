import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_empty_state.dart';
import 'give_repository.dart';

typedef GiveListLoader = Future<List<Map<String, dynamic>>> Function();

class GiveHomePage extends StatefulWidget {
  const GiveHomePage({super.key, this.loadAccounts, this.loadMandates});
  final GiveListLoader? loadAccounts;
  final GiveListLoader? loadMandates;
  @override
  State<GiveHomePage> createState() => _GiveHomePageState();
}

class _GiveHomePageState extends State<GiveHomePage> {
  GiveRepository? repo;
  late Future<List<Map<String, dynamic>>> accounts;
  late Future<List<Map<String, dynamic>>> mandates;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repository = repo ??=
        widget.loadAccounts == null || widget.loadMandates == null
            ? GiveRepository()
            : null;
    accounts = widget.loadAccounts?.call() ?? repository!.accounts();
    mandates = widget.loadMandates?.call() ?? repository!.mandates();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([accounts, mandates]);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              Row(children: [
                Expanded(
                  child: Text('Give',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w600, letterSpacing: -.7)),
                ),
                TextButton(
                    onPressed: () => context.push('/give/history'),
                    child: const Text('History')),
              ]),
              const SizedBox(height: 20),
              const _SectionTitle('Church accounts'),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: accounts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                        height: 112,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SectionEmptyState(
                        icon: PhosphorIcons.warningCircle(),
                        message: 'Unable to load church accounts',
                        height: 112);
                  }
                  final rows = snapshot.data ?? const [];
                  if (rows.isEmpty) {
                    return SectionEmptyState(
                        icon: PhosphorIcons.bank(),
                        message: 'No giving accounts configured',
                        height: 112);
                  }
                  return _ListPanel(children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      _ChurchAccountRow(row: rows[i]),
                      if (i != rows.length - 1) const _Divider(),
                    ],
                  ]);
                },
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Quick accounts'),
              const SizedBox(height: 10),
              _ListPanel(children: [
                _GivingOption(
                    title: 'Offering',
                    subtitle: 'Give your church offering',
                    icon: PhosphorIcons.handCoins(),
                    onTap: () => _pay('offering', 'Offering')),
                const _Divider(),
                _GivingOption(
                    title: 'Tithe',
                    subtitle: 'Give your tithe securely',
                    icon: PhosphorIcons.wallet(),
                    onTap: () => _pay('tithe', 'Tithe')),
                const _Divider(),
                _GivingOption(
                    title: 'Prophet offering',
                    subtitle: 'Give a prophet offering',
                    icon: PhosphorIcons.heartStraight(),
                    onTap: () => _pay('prophet_offering', 'Prophet offering')),
              ]),
              const SizedBox(height: 24),
              const _SectionTitle('Scheduled givings'),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: mandates,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                        height: 112,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SectionEmptyState(
                        icon: PhosphorIcons.warningCircle(),
                        message: 'Unable to load scheduled givings',
                        height: 112);
                  }
                  final rows = snapshot.data ?? const [];
                  if (rows.isEmpty) {
                    return SectionEmptyState(
                        icon: PhosphorIcons.calendarBlank(),
                        message: 'No scheduled givings',
                        height: 112);
                  }
                  return _ListPanel(children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      _ScheduledGivingRow(row: rows[i]),
                      if (i != rows.length - 1) const _Divider(),
                    ],
                  ]);
                },
              ),
            ],
          ),
        ),
      );

  void _pay(String type, String title) => context
      .push('/give/payment', extra: {'giving_type': type, 'title': title});
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500));
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WpccColors.line)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children));
}

class _ChurchAccountRow extends StatelessWidget {
  const _ChurchAccountRow({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final number = row['account_number']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      child: Row(children: [
        const _LeadingIcon(icon: Icons.account_balance_outlined),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(row['account_name']?.toString() ?? 'Church account',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
              [number, row['bank_name']]
                  .where(
                      (value) => value != null && value.toString().isNotEmpty)
                  .join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: WpccColors.muted)),
        ])),
        IconButton(
            tooltip: 'Copy account number',
            onPressed: number.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: number));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Account number copied')));
                    }
                  },
            icon: Icon(PhosphorIcons.copy(), size: 18)),
      ]),
    );
  }
}

class _GivingOption extends StatelessWidget {
  const _GivingOption(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            _LeadingIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: WpccColors.muted)),
                ])),
            Icon(PhosphorIcons.caretRight(), size: 17, color: WpccColors.muted),
          ])));
}

class _ScheduledGivingRow extends StatelessWidget {
  const _ScheduledGivingRow({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final amount =
        (int.tryParse(row['amount_kobo']?.toString() ?? '') ?? 0) / 100;
    final rules = ((row['rule_keys'] as List?) ?? const [])
        .map((rule) => rule.toString().replaceAll('_', ' '))
        .join(' · ');
    final rawType = row['giving_type']?.toString().replaceAll('_', ' ') ??
        'Scheduled giving';
    final type = rawType.isEmpty
        ? rawType
        : '${rawType[0].toUpperCase()}${rawType.substring(1)}';
    return Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          _LeadingIcon(icon: PhosphorIcons.calendarCheck()),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    '$type · ${NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0).format(amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                if (rules.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(rules,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: WpccColors.muted)),
                ],
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: WpccColors.successBackground,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(
                  row['status']?.toString() == 'active' ? 'Active' : 'Paused',
                  style: const TextStyle(
                      fontSize: 9,
                      color: WpccColors.success,
                      fontWeight: FontWeight.w600))),
        ]));
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
          color: WpccColors.subtle, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, size: 19, color: WpccColors.ink));
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, indent: 68, endIndent: 14, color: WpccColors.lineSubtle);
}
