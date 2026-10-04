import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/widgets/member_skeleton.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_components.dart';
import 'give_repository.dart';
import 'giving_history_page.dart';
import 'giving_backdrop.dart';

typedef GiveListLoader = Future<List<Map<String, dynamic>>> Function();

class GiveHomePage extends StatefulWidget {
  const GiveHomePage(
      {super.key,
      this.loadAccounts,
      this.loadMandates,
      this.loadProjects,
      this.loadHistory,
      this.initialHistory = false});
  final GiveListLoader? loadAccounts;
  final GiveListLoader? loadMandates;
  final GiveListLoader? loadProjects;
  final GivingHistoryLoader? loadHistory;
  final bool initialHistory;
  @override
  State<GiveHomePage> createState() => _GiveHomePageState();
}

class _GiveHomePageState extends State<GiveHomePage>
    with SingleTickerProviderStateMixin {
  late final tabAnimation =
      AnimationController(vsync: this, duration: AppMotion.tab, value: 1);
  GiveRepository? repo;
  late Future<List<Map<String, dynamic>>> accounts;
  late Future<List<Map<String, dynamic>>> mandates;
  late Future<List<Map<String, dynamic>>> projects;
  final projectSection = GlobalKey();
  String selectedType = 'offering';
  late bool history;
  late bool historyVisited;
  static const types = {
    'offering': 'Offering',
    'tithe': 'Tithe',
    'prophet_offering': 'Prophet offering',
    'project': 'Projects'
  };

  @override
  void initState() {
    super.initState();
    history = historyVisited = widget.initialHistory;
    _load();
  }

  @override
  void didUpdateWidget(covariant GiveHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHistory != widget.initialHistory) {
      history = widget.initialHistory;
      historyVisited = historyVisited || history;
    }
  }

  void _load() {
    final repository = repo ??= widget.loadAccounts == null ||
            widget.loadMandates == null ||
            widget.loadProjects == null
        ? GiveRepository()
        : null;
    accounts = widget.loadAccounts?.call() ?? repository!.accounts();
    mandates = widget.loadMandates?.call() ?? repository!.mandates();
    projects = widget.loadProjects?.call() ?? repository!.projects();
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await Future.wait([accounts, mandates, projects]);
    } catch (_) {}
  }

  void _showProjects() {
    final target = projectSection.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target,
          duration: AppMotion.duration(context, AppMotion.page),
          curve: AppMotion.curve,
          alignment: .1);
    }
  }

  void _selectTab(bool value) {
    if (history == value) return;
    setState(() {
      history = value;
      historyVisited = historyVisited || value;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      tabAnimation.value = 1;
    } else {
      tabAnimation.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) tabAnimation.value = 1;
  }

  @override
  void dispose() {
    tabAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GivingBackdrop(
        child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Row(children: [
                          Expanded(
                              child: _GivingType(
                                  title: 'Give',
                                  selected: !history,
                                  onTap: () => _selectTab(false))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _GivingType(
                                  title: 'History',
                                  selected: history,
                                  onTap: () => _selectTab(true))),
                        ])),
                    Expanded(
                        child: FadeTransition(
                            opacity: tabAnimation
                                .drive(CurveTween(curve: AppMotion.curve)),
                            child:
                                IndexedStack(index: history ? 1 : 0, children: [
                              TickerMode(
                                  enabled: !history,
                                  child: _giveContent(context)),
                              if (historyVisited)
                                TickerMode(
                                    enabled: history,
                                    child: GivingHistoryPage(
                                        embedded: true,
                                        loadHistory: widget.loadHistory))
                              else
                                const SizedBox.shrink(),
                            ]))),
                  ])),
            )),
      );

  Widget _giveContent(BuildContext context) => RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
          key: const PageStorageKey('give-home-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: memberPagePadding(context, bottom: 124),
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final entry in types.entries)
                      Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _GivingType(
                              title: entry.value,
                              selected: selectedType == entry.key,
                              onTap: () {
                                setState(() => selectedType = entry.key);
                                if (entry.key == 'project') _showProjects();
                              })),
                  ])),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: selectedType == 'project'
                      ? _showProjects
                      : () => _pay(selectedType, types[selectedType]!),
                  icon: Icon(PhosphorIcons.arrowUpRight(), size: 20),
                  iconAlignment: IconAlignment.end,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56)),
                  label: Text(selectedType == 'project'
                      ? 'Choose a project'
                      : 'Give now')),
              const SizedBox(height: 28),
              const MemberSectionHeader(title: 'Church accounts'),
              _section(
                  accounts,
                  'Unable to load church accounts',
                  'No giving accounts configured',
                  (rows) => LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                          key: const PageStorageKey('giving-accounts'),
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < rows.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 16),
                                  SizedBox(
                                      width: (constraints.maxWidth *
                                              (rows.length > 1 ? .88 : 1))
                                          .clamp(0.0, 420.0),
                                      child: _ChurchAccountRow(row: rows[i])),
                                ]
                              ])))),
              const SizedBox(height: 28),
              MemberSectionHeader(
                  key: projectSection, title: 'Church projects'),
              _section(
                  projects,
                  'Unable to load church projects',
                  'No active church projects',
                  (rows) => LayoutBuilder(builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 336 &&
                                MediaQuery.textScalerOf(context).scale(14) <= 22
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 16) /
                                columns;
                        return Wrap(spacing: 16, runSpacing: 16, children: [
                          for (final project in rows)
                            SizedBox(
                                width: width,
                                child: _project(context, project)),
                        ]);
                      })),
              const SizedBox(height: 24),
              _PlainGivingAction(onTap: () => context.push('/give/auto')),
              _section(
                  mandates,
                  'Unable to load scheduled givings',
                  'No scheduled gifts',
                  (rows) => Column(children: [
                        for (final row in rows) _ScheduledGivingRow(row: row),
                      ])),
            ])
          ]));

  Widget _section(Future<List<Map<String, dynamic>>> future, String error,
          String empty, Widget Function(List<Map<String, dynamic>>) content) =>
      FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const MemberSkeleton(rows: 2);
            }
            if (snapshot.hasError) {
              return MemberStatus(
                  icon: PhosphorIcons.warningCircle(),
                  message: error,
                  onRetry: () => setState(() {
                        if (identical(future, accounts)) {
                          accounts =
                              widget.loadAccounts?.call() ?? repo!.accounts();
                        } else if (identical(future, projects)) {
                          projects =
                              widget.loadProjects?.call() ?? repo!.projects();
                        } else {
                          mandates =
                              widget.loadMandates?.call() ?? repo!.mandates();
                        }
                      }));
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return MemberStatus(icon: PhosphorIcons.gift(), message: empty);
            }
            return content(rows);
          });

  Widget _project(BuildContext context, Map<String, dynamic> project) {
    final title = project['title']?.toString() ?? 'Church project';
    final description = project['description']?.toString().trim() ?? '';
    final image = project['image_url']?.toString() ?? '';
    final target =
        num.tryParse(project['target_amount_kobo']?.toString() ?? '');
    return Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
            onTap: project['id'] == null
                ? null
                : () => context.push('/give/payment', extra: {
                      'giving_type': 'project',
                      'project_id': project['id'],
                      'title': title
                    }),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(
                  aspectRatio: 1.6,
                  child: image.isEmpty
                      ? Center(child: Icon(PhosphorIcons.church(), size: 36))
                      : Image.network(image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                              child: Icon(PhosphorIcons.church(), size: 36)))),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall)
                        ],
                        if (target != null && target > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                              'Target: ${NumberFormat.currency(locale: 'en_NG', symbol: 'NGN ', decimalDigits: 0).format(target / 100)}',
                              style: Theme.of(context).textTheme.bodySmall)
                        ],
                      ])),
            ])));
  }

  void _pay(String type, String title) => context
      .push('/give/payment', extra: {'giving_type': type, 'title': title});
}

class _GivingType extends StatelessWidget {
  const _GivingType(
      {required this.title, required this.selected, required this.onTap});
  final String title;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: AnimatedContainer(
                    duration: AppMotion.duration(context, AppMotion.tab),
                    curve: AppMotion.curve,
                    decoration: BoxDecoration(
                        color: selected
                            ? (Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFFD5EACF)
                                : const Color(0xFF314134))
                            : Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24)),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 38),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                      child: Text(title,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  height: 18 / 14,
                                                  color: selected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant)))
                                ]))),
                  )),
            ),
          ),
        ),
      );
}

class _ChurchAccountRow extends StatelessWidget {
  const _ChurchAccountRow({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final number = row['account_number']?.toString() ?? '';
    final bank = row['bank_name']?.toString() ?? '';
    final purpose = row['purpose']?.toString().trim() ?? '';
    final name = row['account_name']?.toString() ??
        row['wallet_name']?.toString() ??
        'Church account';
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF262629),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: .06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _BankLogo(url: row['bank_logo_url']?.toString() ?? ''),
          const SizedBox(width: 12),
          Expanded(
              child: Text(bank.isEmpty ? 'Church account' : bank,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 30),
        Text('Account number', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(number.isEmpty ? 'Account unavailable' : number,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: number.isEmpty ? 16 : 26,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0)))),
          IconButton(
            tooltip: 'Copy account number',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(PhosphorIcons.copy(), size: 22),
            onPressed: number.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: number));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Account number copied')));
                    }
                  },
          ),
        ]),
        const SizedBox(height: 24),
        if (purpose.isNotEmpty) ...[
          Text(purpose, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        Text(name,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
      ]),
    );
  }
}

class _BankLogo extends StatelessWidget {
  const _BankLogo({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12)),
        child: url.isEmpty
            ? Icon(PhosphorIcons.gift(), size: 20)
            : Image.network(url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(PhosphorIcons.bank(), size: 20)),
      );
}

class _PlainGivingAction extends StatelessWidget {
  const _PlainGivingAction({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Manage scheduled givings',
        child: MemberListRow(
            plain: true,
            title: 'Scheduled giving',
            subtitle: 'Recurring gifts',
            onTap: onTap),
      );
}

class _ScheduledGivingRow extends StatelessWidget {
  const _ScheduledGivingRow({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final amount =
        (int.tryParse(row['amount_kobo']?.toString() ?? '') ?? 0) / 100;
    final rules = ((row['rule_keys'] as List?) ?? const [])
        .map((rule) {
          final parts = rule.toString().split(':');
          final day = parts.length > 1 ? int.tryParse(parts[1]) : null;
          if (parts.first == 'weekday' && day != null && day >= 1 && day <= 7) {
            return const [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday'
            ][day - 1];
          }
          return 'Service day';
        })
        .toSet()
        .join(' · ');
    final rawType = row['giving_type']?.toString().replaceAll('_', ' ') ??
        'Scheduled giving';
    final type = rawType.isEmpty
        ? rawType
        : '${rawType[0].toUpperCase()}${rawType.substring(1)}';
    final status = row['status']?.toString() == 'active' ? 'Active' : 'Paused';
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(PhosphorIcons.calendarCheck(), size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    '$type · ${NumberFormat.currency(locale: 'en_NG', symbol: 'NGN ', decimalDigits: 0).format(amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        height: 21 / 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text([status, if (rules.isNotEmpty) rules].join(' · '),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5)),
              ])),
        ]));
  }
}
