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
                  return _AccountRail(rows: rows);
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

class _AccountRail extends StatefulWidget {
  const _AccountRail({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  State<_AccountRail> createState() => _AccountRailState();
}

class _AccountRailState extends State<_AccountRail> {
  final controller = ScrollController();
  int selected = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth * .88).clamp(260.0, 360.0);
          return Column(children: [
            SizedBox(
              height: 172,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification ||
                      notification is ScrollEndNotification) {
                    final next = (controller.offset / (cardWidth + 10))
                        .round()
                        .clamp(0, widget.rows.length - 1);
                    if (next != selected) setState(() => selected = next);
                  }
                  return false;
                },
                child: ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 18),
                  itemCount: widget.rows.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => SizedBox(
                    width: cardWidth,
                    child: _ChurchAccountCard(
                        row: widget.rows[index], variant: index % 3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.rows.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected == index ? 18 : 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: selected == index
                        ? WpccColors.ink
                        : const Color(0xFFD5D7DC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ]);
        },
      );
}

class _ChurchAccountCard extends StatelessWidget {
  const _ChurchAccountCard({required this.row, required this.variant});
  final Map<String, dynamic> row;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final number = row['account_number']?.toString() ?? '';
    final dark = variant == 0;
    final warm = variant == 2;
    final foreground = dark ? Colors.white : WpccColors.ink;
    final muted =
        dark ? Colors.white.withValues(alpha: .7) : WpccColors.inkSoft;
    final colors = dark
        ? const [Color(0xFF202229), Color(0xFF111217)]
        : warm
            ? const [Color(0xFFFBF6ED), Color(0xFFF3EADB)]
            : const [Colors.white, Color(0xFFF5F5F6)];
    return Container(
      padding: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: .08)
                : warm
                    ? const Color(0xFFEEE4D2)
                    : WpccColors.line),
        boxShadow: const [
          BoxShadow(
              color: Color(0x121C1E24), blurRadius: 28, offset: Offset(0, 12))
        ],
      ),
      child: Stack(children: [
        Positioned(
          width: 150,
          height: 150,
          right: -72,
          top: -70,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark
                  ? Colors.white.withValues(alpha: .07)
                  : WpccColors.ink.withValues(alpha: .035),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['bank_name']?.toString() ?? 'Church bank',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: foreground)),
              const SizedBox(height: 2),
              Text(variant == 0 ? 'Main church account' : 'Church account',
                  style: TextStyle(fontSize: 10, color: muted)),
            ]),
            Icon(PhosphorIcons.bank(), size: 20, color: foreground),
          ]),
          const SizedBox(height: 26),
          Text(number,
              style: TextStyle(
                  fontSize: 27,
                  height: 1,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w600,
                  color: foreground)),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACCOUNT NAME',
                        style: TextStyle(fontSize: 9, color: muted)),
                    const SizedBox(height: 2),
                    Text(row['account_name']?.toString() ?? 'Church account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: foreground)),
                  ]),
            ),
            IconButton.filledTonal(
                tooltip: 'Copy account number',
                style: IconButton.styleFrom(
                  fixedSize: const Size(38, 38),
                  backgroundColor: dark
                      ? Colors.white.withValues(alpha: .11)
                      : Colors.white.withValues(alpha: .72),
                  foregroundColor: foreground,
                  side: BorderSide(
                      color: dark
                          ? Colors.white.withValues(alpha: .18)
                          : WpccColors.line),
                ),
                onPressed: number.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: number));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Account number copied')));
                        }
                      },
                icon: Icon(PhosphorIcons.copy(), size: 17)),
          ]),
        ]),
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
