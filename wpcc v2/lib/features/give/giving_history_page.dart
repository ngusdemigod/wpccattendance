import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/services/receipt_export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_empty_state.dart';
import 'give_repository.dart';

class GivingHistoryPage extends StatefulWidget {
  const GivingHistoryPage({super.key});

  @override
  State<GivingHistoryPage> createState() => _GivingHistoryPageState();
}

class _GivingHistoryPageState extends State<GivingHistoryPage> {
  static const pageSize = 25;
  final repo = GiveRepository();
  final rows = <Map<String, dynamic>>[];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  Object? error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
        hasMore = true;
        rows.clear();
      });
    }
    try {
      final first = await repo.history(limit: pageSize, offset: 0);
      if (!mounted) return;
      setState(() {
        rows.addAll(first);
        hasMore = first.length == pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (loadingMore || !hasMore) return;
    setState(() => loadingMore = true);
    try {
      final next = await repo.history(limit: pageSize, offset: rows.length);
      if (!mounted) return;
      setState(() {
        rows.addAll(next);
        hasMore = next.length == pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load more giving history: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
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
                  child: Center(child: CircularProgressIndicator()),
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
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: _loadMore,
                              child: const Text('Load more'),
                            ),
                    ),
                  );
                }
                return _row(context, rows[index]);
              },
            ),
          );
        },
      ),
    ),
  );

  Widget _row(BuildContext context, Map<String, dynamic> tx) {
    final successful = tx['status'] == 'successful';
    return InkWell(
      onTap: () => _invoice(tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: successful
                    ? const Color(0xFFEAF7EF)
                    : const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                successful
                    ? PhosphorIcons.checkCircle()
                    : PhosphorIcons.receipt(),
                size: 18,
                color: successful
                    ? const Color(0xFF247A49)
                    : WpccColors.inkSoft,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _date(tx),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: WpccColors.muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _amount(tx),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _label(tx['status']),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: WpccColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _invoice(Map<String, dynamic> tx) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
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
      'd MMM yyyy · h:mm a',
    ).format(d.toUtc().add(const Duration(hours: 1)));
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giving receipt',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          _detail('Status', tx['status']),
          _detail('Date', dateLabel),
          _detail(
            'Reference',
            tx['paystack_reference'] ?? tx['internal_reference'],
          ),
          _detail(
            'Payment source',
            tx['source_summary'] ?? tx['payment_channel'] ?? 'Paystack',
          ),
          _detail('Receipt type', tx['receipt_type'] ?? 'PDF receipt'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => exporter.downloadPdf(tx),
                  style: FilledButton.styleFrom(
                    backgroundColor: WpccColors.ink,
                  ),
                  icon: Icon(PhosphorIcons.filePdf(), size: 17),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exporter.downloadImage(tx),
                  icon: Icon(PhosphorIcons.image(), size: 17),
                  label: const Text('Download image'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: WpccColors.muted),
          ),
        ),
        Expanded(
          child: Text(
            (value?.toString() ?? '—').replaceAll('_', ' '),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
