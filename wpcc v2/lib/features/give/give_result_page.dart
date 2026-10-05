import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/services/receipt_export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_glass.dart';
import 'giving_backdrop.dart';
import 'give_repository.dart';

class GiveResultPage extends StatefulWidget {
  const GiveResultPage({super.key, required this.reference, this.repository});
  final String reference;
  final GiveRepository? repository;

  @override
  State<GiveResultPage> createState() => _GiveResultPageState();
}

class _GiveResultPageState extends State<GiveResultPage> {
  late final repo = widget.repository ?? GiveRepository();
  final exporter = const ReceiptExportService();
  late Future<_PaymentLookup> future;

  @override
  void initState() {
    super.initState();
    future = _verify();
  }

  Future<_PaymentLookup> _verify() async {
    if (widget.reference.isEmpty) return const _PaymentLookup.notFound();
    try {
      return _PaymentLookup.data(await repo.verify(widget.reference));
    } catch (_) {
      try {
        final transaction = await repo.transactionByReference(widget.reference);
        return transaction == null
            ? const _PaymentLookup.notFound()
            : _PaymentLookup.data(transaction);
      } catch (_) {
        return const _PaymentLookup.transientError();
      }
    }
  }

  void _retry() => setState(() => future = _verify());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PaymentLookup>(
        future: future,
        builder: (context, snapshot) => GivingBackdrop(
            status: snapshot.connectionState != ConnectionState.done
                ? 'processing'
                : snapshot.data?.transaction?['status']?.toString(),
            child: Scaffold(
              body: SafeArea(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Builder(
                          builder: (context) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final lookup = snapshot.data ??
                                const _PaymentLookup.transientError();
                            if (lookup.state == _PaymentLookupState.notFound) {
                              return _notFound(context);
                            }
                            if (lookup.state ==
                                _PaymentLookupState.transientError) {
                              return _transientError(context);
                            }
                            final tx = lookup.transaction!;
                            final status =
                                tx['status']?.toString() ?? 'pending';
                            final successful = status == 'successful';
                            final pending = status == 'pending' ||
                                status == 'initialized' ||
                                status == 'processing';
                            return ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 32),
                              children: [
                                Row(children: [
                                  Expanded(
                                      child: Text('Giving',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge)),
                                  MemberIconButton(
                                      icon: PhosphorIcons.x(),
                                      label: 'Back to Give',
                                      onPressed: () => context.go('/give')),
                                ]),
                                const SizedBox(height: 32),
                                Center(
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: successful
                                          ? WpccColors.successBackground
                                          : pending
                                              ? WpccColors.warningBackground
                                              : WpccColors.errorBackground,
                                    ),
                                    child: Icon(
                                      successful
                                          ? PhosphorIcons.check()
                                          : pending
                                              ? PhosphorIcons.clockCountdown()
                                              : PhosphorIcons.x(),
                                      size: 28,
                                      color: successful
                                          ? WpccColors.success
                                          : pending
                                              ? WpccColors.warning
                                              : WpccColors.error,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  successful
                                      ? 'Giving successful'
                                      : pending
                                          ? 'Payment pending'
                                          : 'Payment failed',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (successful)
                                  Text(
                                    'Thank you for your generosity.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  ),
                                if (successful) const SizedBox(height: 18),
                                FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _amount(tx),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontSize: 46,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    )),
                                const SizedBox(height: 32),
                                MemberGlass(
                                    radius: 20,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              successful
                                                  ? 'Receipt'
                                                  : 'Payment details',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          const SizedBox(height: 12),
                                          _row('Giving type',
                                              _label(tx['giving_type'])),
                                          _row(
                                            'Payment source',
                                            tx['source_summary']?.toString() ??
                                                tx['payment_channel']
                                                    ?.toString() ??
                                                'Paystack',
                                          ),
                                          _row('Status', _label(status)),
                                          const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
                                              child: Divider(height: 1)),
                                          Row(children: [
                                            Expanded(
                                                child: Text(
                                                    'Transaction reference',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall)),
                                            IconButton(
                                                tooltip: 'Copy reference',
                                                onPressed: () async {
                                                  final reference =
                                                      tx['paystack_reference']
                                                              ?.toString() ??
                                                          tx['internal_reference']
                                                              ?.toString() ??
                                                          widget.reference;
                                                  await Clipboard.setData(
                                                      ClipboardData(
                                                          text: reference));
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Reference copied')));
                                                  }
                                                },
                                                icon: Icon(PhosphorIcons.copy(),
                                                    size: 18)),
                                          ]),
                                          SelectableText(
                                              tx['paystack_reference']
                                                      ?.toString() ??
                                                  tx['internal_reference']
                                                      ?.toString() ??
                                                  widget.reference,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        ],
                                      ),
                                    )),
                                if (successful) ...[
                                  const SizedBox(height: 24),
                                  Text('Download receipt',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              exporter.downloadPdf(tx),
                                          icon: Icon(PhosphorIcons.filePdf(),
                                              size: 17),
                                          label: const Text('PDF'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              exporter.downloadImage(tx),
                                          icon: Icon(PhosphorIcons.image(),
                                              size: 17),
                                          label: const Text('Image'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (pending) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _retry,
                                    icon: Icon(PhosphorIcons.arrowClockwise(),
                                        size: 17),
                                    label: const Text('Check payment status'),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: () => context.go('/give'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.onSurface,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  child: const Text('Back to Give'),
                                ),
                              ],
                            );
                          },
                        ))),
              ),
            )));
  }

  Widget _notFound(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.warningCircle(), size: 42, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('Payment not found'),
            TextButton(
              onPressed: () => context.go('/give'),
              child: const Text('Back to Give'),
            ),
          ],
        ),
      );

  Widget _transientError(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.warningCircle(), size: 42, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('Unable to check payment status'),
            const SizedBox(height: 4),
            const Text('Check your connection and try again.'),
            TextButton(onPressed: _retry, child: const Text('Retry')),
            TextButton(
              onPressed: () => context.go('/give'),
              child: const Text('Back to Give'),
            ),
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  String _amount(Map<String, dynamic> tx) => NumberFormat.currency(
        locale: 'en_NG',
        symbol: '₦',
        decimalDigits: 2,
      ).format((int.tryParse(tx['amount_kobo']?.toString() ?? '') ?? 0) / 100);

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

enum _PaymentLookupState { data, notFound, transientError }

class _PaymentLookup {
  const _PaymentLookup.data(this.transaction)
      : state = _PaymentLookupState.data;
  const _PaymentLookup.notFound()
      : state = _PaymentLookupState.notFound,
        transaction = null;
  const _PaymentLookup.transientError()
      : state = _PaymentLookupState.transientError,
        transaction = null;

  final _PaymentLookupState state;
  final Map<String, dynamic>? transaction;
}
