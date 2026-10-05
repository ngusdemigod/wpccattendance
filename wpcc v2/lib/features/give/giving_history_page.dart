import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/services/receipt_export_service.dart';
import '../../core/widgets/section_empty_state.dart';
import 'give_repository.dart';
import '../../core/widgets/member_skeleton.dart';
import '../../core/widgets/member_sheet.dart';

typedef GivingHistoryLoader = Future<List<Map<String, dynamic>>> Function(
    {required int limit, required int offset});

class GivingHistoryPage extends StatefulWidget {
  const GivingHistoryPage({super.key, this.embedded = false, this.loadHistory});
  final bool embedded;
  final GivingHistoryLoader? loadHistory;

  @override
  State<GivingHistoryPage> createState() => _GivingHistoryPageState();
}

class _GivingHistoryPageState extends State<GivingHistoryPage> {
  static const pageSize = 25;
  late final repo = widget.loadHistory == null ? GiveRepository() : null;
  Future<List<Map<String, dynamic>>> _fetch(int offset) =>
      widget.loadHistory?.call(limit: pageSize, offset: offset) ??
      repo!.history(limit: pageSize, offset: offset);
  final rows = <Map<String, dynamic>>[];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  Object? error;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final requestGeneration = ++generation;
    if (mounted) {
      setState(() {
        loading = true;
        loadingMore = false;
        error = null;
        hasMore = true;
        rows.clear();
      });
    }
    try {
      final first = await _fetch(0);
      if (!mounted || requestGeneration != generation) return;
      setState(() {
        rows.addAll(first);
        hasMore = first.length == pageSize;
      });
    } catch (e) {
      if (mounted && requestGeneration == generation) setState(() => error = e);
    } finally {
      if (mounted && requestGeneration == generation) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final requestGeneration = generation;
    setState(() => loadingMore = true);
    try {
      final next = await _fetch(rows.length);
      if (!mounted || requestGeneration != generation) return;
      setState(() {
        rows.addAll(next);
        hasMore = next.length == pageSize;
      });
    } catch (e) {
      if (mounted && requestGeneration == generation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load more giving history: $e')),
        );
      }
    } finally {
      if (mounted && requestGeneration == generation) {
        setState(() => loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.embedded
            ? null
            : AppBar(
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(PhosphorIcons.caretLeft(), size: 20),
                ),
                title: const Text(
                  'Giving history',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Builder(
            builder: (context) {
              if (loading) {
                return ListView(
                  children: const [
                    SizedBox(
                      height: 260,
                      child: Padding(
                          padding: EdgeInsets.all(20), child: MemberSkeleton()),
                    ),
                  ],
                );
              }
              if (error != null) {
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    SectionEmptyState(
                      icon: PhosphorIcons.warningCircle(),
                      message: 'Unable to load giving history',
                      height: 220,
                    ),
                    TextButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                );
              }
              if (rows.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    SectionEmptyState(
                      icon: PhosphorIcons.receipt(),
                      message: 'No giving transactions yet',
                      height: 260,
                    ),
                  ],
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 220) _loadMore();
                  return false;
                },
                child: ListView.separated(
                  key: const PageStorageKey('giving-history-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      20, 12, 20, widget.embedded ? 124 : 28),
                  itemCount: rows.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, index) => index < rows.length - 1
                      ? const Divider(height: 1)
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    if (index == rows.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: loadingMore
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : TextButton(
                                  onPressed: _loadMore,
                                  child: const Text('Load more'),
                                ),
                        ),
                      );
                    }
                    final month = _month(rows[index]);
                    final startsMonth =
                        index == 0 || _month(rows[index - 1]) != month;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (startsMonth)
                            Padding(
                              padding: EdgeInsets.only(
                                  top: index == 0 ? 4 : 24, bottom: 12),
                              child: Semantics(
                                  header: true,
                                  child: Text(month,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium)),
                            ),
                          _row(context, rows[index]),
                        ]);
                  },
                ),
              );
            },
          ),
        ),
      );

  Widget _row(BuildContext context, Map<String, dynamic> tx) {
    final successful = tx['status'] == 'successful';
    final pending =
        const ['pending', 'initialized', 'processing'].contains(tx['status']);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final color = successful
        ? (dark ? const Color(0xFF91DDB5) : const Color(0xFF246747))
        : pending
            ? (dark ? const Color(0xFFF1D17C) : const Color(0xFF80620C))
            : (dark ? const Color(0xFFFFABB0) : const Color(0xFFA72B3A));
    return InkWell(
      onTap: () => _invoice(tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                successful
                    ? PhosphorIcons.checkCircle()
                    : pending
                        ? PhosphorIcons.clockCountdown()
                        : PhosphorIcons.xCircle(),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(tx['giving_type']),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _date(tx),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _amount(tx),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  tx['status'] == 'initialized'
                      ? 'Processing'
                      : _label(tx['status']),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: color,
                      ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _invoice(Map<String, dynamic> tx) => showMemberSheet<void>(
        context: context,
        title: 'Giving receipt',
        builder: (context) => _InvoiceSheet(tx: tx),
      );

  String _amount(Map<String, dynamic> tx) => NumberFormat.currency(
        locale: 'en_NG',
        symbol: '₦',
        decimalDigits: 2,
      ).format((int.tryParse(tx['amount_kobo']?.toString() ?? '') ?? 0) / 100);

  String _date(Map<String, dynamic> tx) {
    final d = DateTime.tryParse(
      (tx['paid_at'] ?? tx['initiated_at'] ?? tx['created_at'])?.toString() ??
          '',
    );
    if (d == null) return '—';
    return DateFormat(
      'd MMM · h:mm a',
    ).format(d.toUtc().add(const Duration(hours: 1)));
  }

  String _month(Map<String, dynamic> tx) {
    final date = DateTime.tryParse(
        (tx['paid_at'] ?? tx['initiated_at'] ?? tx['created_at'])?.toString() ??
            '');
    return date == null
        ? 'Other transactions'
        : DateFormat('MMMM yyyy')
            .format(date.toUtc().add(const Duration(hours: 1)));
  }

  String _label(dynamic value) => (value?.toString() ?? '—')
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

class _InvoiceSheet extends StatelessWidget {
  const _InvoiceSheet({required this.tx});
  final Map<String, dynamic> tx;
  static const exporter = ReceiptExportService();

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    ).format((int.tryParse(tx['amount_kobo']?.toString() ?? '') ?? 0) / 100);
    final date = DateTime.tryParse(
      (tx['paid_at'] ?? tx['initiated_at'] ?? tx['created_at'])?.toString() ??
          '',
    );
    final dateLabel = date == null
        ? '—'
        : DateFormat(
            'd MMM yyyy · h:mm a',
          ).format(date.toUtc().add(const Duration(hours: 1)));
    final successful = tx['status'] == 'successful';
    final failed = ['failed', 'abandoned', 'reversed'].contains(tx['status']);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = successful
        ? (dark ? const Color(0xFF89D6B6) : const Color(0xFF237451))
        : failed
            ? Theme.of(context).colorScheme.error
            : (dark ? const Color(0xFFE8CB73) : const Color(0xFF806314));

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
                successful
                    ? PhosphorIcons.checkCircle()
                    : failed
                        ? PhosphorIcons.warningCircle()
                        : PhosphorIcons.clockCountdown(),
                size: 20,
                color: statusColor),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    tx['status'] == 'successful'
                        ? 'Giving successful'
                        : 'Payment ${tx['status'] ?? 'pending'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: statusColor))),
          ]),
          const SizedBox(height: 16),
          Text(
            amount,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          const Divider(height: 24),
          _detail(context, 'Giving type', tx['giving_type']),
          _detail(context, 'Date', dateLabel),
          _detail(
            context,
            'Reference',
            tx['paystack_reference'] ?? tx['internal_reference'],
          ),
          _detail(
            context,
            'Payment source',
            tx['source_summary'] ?? tx['payment_channel'] ?? 'Paystack',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => exporter.downloadPdf(tx),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  icon: Icon(PhosphorIcons.filePdf(), size: 17),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exporter.downloadImage(tx),
                  icon: Icon(PhosphorIcons.image(), size: 17),
                  label: const Text('Image'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Text(
                (value?.toString() ?? '—').replaceAll('_', ' '),
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}
