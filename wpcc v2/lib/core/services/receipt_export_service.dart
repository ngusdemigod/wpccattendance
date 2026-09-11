import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

class ReceiptExportService {
  const ReceiptExportService();

  Future<void> downloadPdf(Map<String, dynamic> tx) async {
    final document = pw.Document();
    final amount = _amount(tx);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('WPCC Community',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Giving receipt',
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 28),
            pw.Text(amount,
                style:
                    pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            _pdfRow('Type', _label(tx['giving_type'])),
            _pdfRow('Status', _label(tx['status'])),
            _pdfRow(
                'Reference',
                tx['paystack_reference']?.toString() ??
                    tx['internal_reference']?.toString() ??
                    '—'),
            _pdfRow(
                'Payment source',
                tx['source_summary']?.toString() ??
                    tx['payment_channel']?.toString() ??
                    'Paystack'),
            _pdfRow('Date', _date(tx)),
            pw.Spacer(),
            pw.Text('Generated from trusted WPCC Community transaction data.',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
    _download(await document.save(), 'wpcc-receipt-${_safeRef(tx)}.pdf',
        'application/pdf');
  }

  Future<void> downloadImage(Map<String, dynamic> tx) async {
    final ref = _xml(tx['paystack_reference']?.toString() ??
        tx['internal_reference']?.toString() ??
        '—');
    final source = _xml(tx['source_summary']?.toString() ??
        tx['payment_channel']?.toString() ??
        'Paystack');
    final svg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1350" viewBox="0 0 1080 1350">
<rect width="1080" height="1350" rx="72" fill="#F6F7FA"/>
<rect x="70" y="70" width="940" height="1210" rx="52" fill="white"/>
<text x="120" y="170" font-family="Arial, sans-serif" font-size="46" font-weight="700" fill="#111217">WPCC Community</text>
<text x="120" y="220" font-family="Arial, sans-serif" font-size="28" fill="#8B8C93">Giving receipt</text>
<text x="120" y="380" font-family="Arial, sans-serif" font-size="80" font-weight="700" fill="#111217">${_xml(_amount(tx))}</text>
${_svgRow(500, 'Type', _label(tx['giving_type']))}
${_svgRow(610, 'Status', _label(tx['status']))}
${_svgRow(720, 'Reference', ref)}
${_svgRow(830, 'Payment source', source)}
${_svgRow(940, 'Date', _date(tx))}
<text x="120" y="1180" font-family="Arial, sans-serif" font-size="23" fill="#8B8C93">Generated from trusted WPCC Community transaction data.</text>
</svg>''';
    _download(Uint8List.fromList(utf8.encode(svg)),
        'wpcc-receipt-${_safeRef(tx)}.svg', 'image/svg+xml');
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7),
        child: pw.Row(children: [
          pw.SizedBox(
              width: 130,
              child: pw.Text(label,
                  style: const pw.TextStyle(color: PdfColors.grey700))),
          pw.Expanded(child: pw.Text(value)),
        ]),
      );

  String _svgRow(int y, String label, String value) =>
      '<text x="120" y="$y" font-family="Arial, sans-serif" font-size="25" fill="#8B8C93">${_xml(label)}</text><text x="420" y="$y" font-family="Arial, sans-serif" font-size="28" font-weight="600" fill="#1C1E24">${_xml(value)}</text>';

  String _amount(Map<String, dynamic> tx) {
    final kobo = int.tryParse(tx['amount_kobo']?.toString() ?? '') ?? 0;
    return NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2)
        .format(kobo / 100);
  }

  String _date(Map<String, dynamic> tx) {
    final raw = tx['paid_at'] ?? tx['initiated_at'] ?? tx['created_at'];
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return '—';
    final lagos = date.toUtc().add(const Duration(hours: 1));
    return DateFormat('d MMM yyyy · h:mm a').format(lagos);
  }

  String _label(dynamic value) => (value?.toString() ?? '—')
      .replaceAll('_', ' ')
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
  String _safeRef(Map<String, dynamic> tx) =>
      (tx['paystack_reference']?.toString() ??
              tx['internal_reference']?.toString() ??
              'receipt')
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
  String _xml(String value) =>
      const HtmlEscape(HtmlEscapeMode.element).convert(value);

  void _download(Uint8List bytes, String filename, String mime) {
    final anchor = web.HTMLAnchorElement()
      ..href = 'data:$mime;base64,${base64Encode(bytes)}'
      ..download = filename;
    anchor.click();
  }
}
