import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/services/receipt_export_service.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_reveal.dart';

/// PDF and image receipt buttons with visible progress, success and error
/// feedback. Creating the file and handing it to the browser can take a moment
/// and can fail, so neither is ever fire-and-forget.
class ReceiptActions extends StatefulWidget {
  const ReceiptActions(
      {super.key,
      required this.transaction,
      this.exporter = const ReceiptExportService(),
      this.filledPdf = false});
  final Map<String, dynamic> transaction;
  final ReceiptExportService exporter;

  /// Gives the PDF button the filled style (used where it is the main action).
  final bool filledPdf;

  @override
  State<ReceiptActions> createState() => _ReceiptActionsState();
}

enum _Kind { pdf, image }

class _ReceiptActionsState extends State<ReceiptActions> {
  _Kind? busy;
  String? message;
  bool failed = false;
  int run = 0;

  Future<void> _export(_Kind kind) async {
    if (busy != null) return;
    final current = ++run;
    setState(() {
      busy = kind;
      message = null;
      failed = false;
    });
    String? text;
    var error = false;
    try {
      final outcome = kind == _Kind.pdf
          ? await widget.exporter.downloadPdf(widget.transaction)
          : await widget.exporter.downloadImage(widget.transaction);
      final label = kind == _Kind.pdf ? 'PDF receipt' : 'Image receipt';
      text = switch (outcome) {
        ReceiptSaveOutcome.shared => '$label shared.',
        ReceiptSaveOutcome.saved => '$label saved.',
        ReceiptSaveOutcome.downloaded =>
          '$label downloaded. Check your downloads.',
        ReceiptSaveOutcome.cancelled => null,
      };
    } catch (_) {
      error = true;
      text = 'We could not create the receipt. Please try again.';
    }
    if (!mounted || current != run) return;
    setState(() {
      busy = null;
      message = text;
      failed = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(child: _button(context, _Kind.pdf)),
          const SizedBox(width: 8),
          Expanded(child: _button(context, _Kind.image)),
        ]),
        MemberSwap(
          child: message == null
              ? const SizedBox(key: ValueKey('none'), width: double.infinity)
              : Padding(
                  key: ValueKey('$failed$message'),
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                            failed
                                ? PhosphorIcons.warningCircle()
                                : PhosphorIcons.checkCircle(),
                            size: 18,
                            color: failed ? scheme.error : scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(message!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: failed
                                            ? scheme.error
                                            : scheme.onSurface))),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _button(BuildContext context, _Kind kind) {
    final isPdf = kind == _Kind.pdf;
    final working = busy == kind;
    final label = isPdf ? 'PDF' : 'Image';
    final icon = AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.tab),
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve.flipped,
      child: working
          ? const SizedBox(
              key: ValueKey('busy'),
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(isPdf ? PhosphorIcons.filePdf() : PhosphorIcons.image(),
              key: const ValueKey('icon'), size: 17),
    );
    final onPressed = busy == null ? () => _export(kind) : null;
    final text = Text(working ? 'Preparing…' : label);
    final scheme = Theme.of(context).colorScheme;
    return AppPressMotion(
      child: isPdf && widget.filledPdf
          ? FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: scheme.onSurface,
                  foregroundColor: scheme.surface),
              icon: icon,
              label: text)
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: icon,
              label: text),
    );
  }
}
