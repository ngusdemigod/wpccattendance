import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/widgets/member_components.dart';
import '../../core/theme/member_theme.dart';
import 'rewards_repository.dart';

class RewardsCard extends StatefulWidget {
  const RewardsCard({super.key, this.compact = false, this.loadSummary});
  final bool compact;
  final Future<Map<String, dynamic>> Function()? loadSummary;
  @override
  State<RewardsCard> createState() => _RewardsCardState();
}

class _RewardsCardState extends State<RewardsCard> with WidgetsBindingObserver {
  late final repo = RewardsRepository();
  final presentationRevision = ValueNotifier(0);
  Map<String, dynamic>? data;
  bool loading = true;
  bool failed = false;
  Timer? refresh;
  int? previousBalance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  Future<void> load() async {
    refresh?.cancel();
    try {
      final result = await (widget.loadSummary ?? repo.summary)();
      if (!mounted) return;
      final balance = (result['balance'] as num).toInt();
      if (previousBalance != null && balance > previousBalance!) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('+${balance - previousBalance!} WP confirmed'),
        ));
      }
      previousBalance = balance;
      setState(() {
        data = result;
        loading = false;
        failed = false;
      });
      presentationRevision.value++;
      if ((result['pending'] as num) > 0 &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        refresh = Timer(const Duration(seconds: 60), load);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          failed = true;
        });
        presentationRevision.value++;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      load();
    } else {
      refresh?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    refresh?.cancel();
    presentationRevision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.compact ? _compact(context) : _expanded(context);

  Widget _expanded(BuildContext context) => Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.stars_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('Wisdom Points',
                          style: Theme.of(context).textTheme.titleMedium)),
                  IconButton(
                      onPressed: load,
                      tooltip: 'Refresh points',
                      icon: const Icon(Icons.refresh)),
                ]),
                if (loading)
                  const LinearProgressIndicator()
                else if (failed)
                  const Text(
                      'Points are temporarily unavailable. Tap refresh to retry.')
                else ...[
                  Text('${data!['balance']} WP',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text((data!['pending'] as num) > 0
                      ? 'Verified activity awaiting points confirmation'
                      : 'Earned through participation'),
                  ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Your points history'),
                      children: [
                        if ((data!['history'] as List).isEmpty)
                          const ListTile(title: Text('No points awarded yet')),
                        for (final entry in data!['history'] as List)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_label(entry['kind'].toString())),
                              subtitle: Text(
                                  DateTime.parse(entry['created_at'].toString())
                                      .toLocal()
                                      .toString()
                                      .substring(0, 16)),
                              trailing: Text(
                                  '${(entry['delta'] as num) > 0 ? '+' : ''}${entry['delta']} WP')),
                      ]),
                ],
              ],
            )),
      );

  Widget _compact(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pending = data != null && (data!['pending'] as num) > 0;
    return MemberListRow(
      title: 'Wisdom Points',
      subtitle: loading
          ? 'Loading points'
          : failed
              ? 'Temporarily unavailable'
              : pending
                  ? 'Awaiting confirmation'
                  : 'Earned through participation',
      leading: Container(
        width: 64,
        height: 66,
        decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(PhosphorIconsRegular.gift, size: 24),
      ),
      trailing: loading
          ? const SizedBox.square(
              dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : failed
              ? MemberIconButton(
                  icon: PhosphorIconsRegular.arrowClockwise,
                  label: 'Retry points',
                  onPressed: load,
                  plain: true)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('${data!['balance']} WP',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  Icon(PhosphorIconsRegular.caretRight,
                      size: 16, color: MemberVisuals.subtle(context)),
                ]),
      onTap: loading || failed
          ? null
          : () async {
              await showModalBottomSheet<void>(
                context: context,
                useSafeArea: true,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (context) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
                  child: AnimatedBuilder(
                    animation: presentationRevision,
                    builder: (context, _) => _expanded(context),
                  ),
                ),
              );
            },
    );
  }

  String _label(String kind) => switch (kind) {
        'attendance' => 'Attendance',
        'prayer' => 'Global prayer',
        'giving' => 'Giving',
        'profile' => 'Profile completion',
        _ => 'Points adjustment',
      };
}
