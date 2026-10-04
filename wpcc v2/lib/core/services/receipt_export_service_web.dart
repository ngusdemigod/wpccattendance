import 'dart:convert';
import 'package:barcode/barcode.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

class ReceiptExportService {
  const ReceiptExportService();

  static const _logoPath = 'assets/images/wpcc_logo.png';
  static const _ink = PdfColor.fromInt(0xFF1C202D);
  static const _muted = PdfColor.fromInt(0xFF737887);
  static const _line = PdfColor.fromInt(0xFFE4E6EC);
  static const _surface = PdfColor.fromInt(0xFFF6F7FA);
  static const _purple = PdfColor.fromInt(0xFF7C3FB2);

  Future<void> downloadPdf(Map<String, dynamic> tx) async {
    final logo = pw.MemoryImage(
      (await rootBundle.load(_logoPath)).buffer.asUint8List(),
    );
    final document = pw.Document(
      title: 'WPCC giving receipt ${_reference(tx)}',
      author: 'Wisdom Power Christian Centre',
    )..addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Container(
            color: _surface,
            alignment: pw.Alignment.center,
            child: _pdfReceipt(tx, logo),
          ),
        ),
      );
    _download(
      await document.save(),
      'wpcc-receipt-${_safeRef(tx)}.pdf',
      'application/pdf',
    );
  }

  pw.Widget _pdfReceipt(Map<String, dynamic> tx, pw.ImageProvider logo) =>
      pw.Container(
        width: 390,
        padding: const pw.EdgeInsets.fromLTRB(34, 36, 34, 28),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(20),
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Image(logo, width: 62, height: 62, fit: pw.BoxFit.contain),
            pw.SizedBox(height: 18),
            pw.Text(
              'Thank you for giving!',
              style: pw.TextStyle(
                color: _ink,
                fontSize: 23,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 7),
            pw.Text(
              'Your gift has been received successfully.',
              style: const pw.TextStyle(color: _muted, fontSize: 11),
            ),
            pw.SizedBox(height: 24),
            _pdfDivider(),
            pw.SizedBox(height: 22),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: _pdfField('RECEIPT ID', _reference(tx)),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 2,
                  child: _pdfField('AMOUNT', _amount(tx)),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: _pdfField('DATE & TIME', _date(tx)),
            ),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _surface,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                children: [
                  _pdfRow('Giving type', _label(tx['giving_type'])),
                  pw.SizedBox(height: 9),
                  _pdfRow('Payment source', _source(tx)),
                  pw.SizedBox(height: 9),
                  _pdfRow('Status', _label(tx['status'])),
                ],
              ),
            ),
            pw.SizedBox(height: 22),
            _pdfDivider(),
            pw.SizedBox(height: 22),
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: _barcodeData(tx),
              width: 270,
              height: 72,
              drawText: false,
              color: _ink,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              _reference(tx),
              style: const pw.TextStyle(
                color: _muted,
                fontSize: 8,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Wisdom Power Christian Centre',
              style: pw.TextStyle(
                color: _purple,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated from a verified WPCC transaction.',
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ],
        ),
      );

  pw.Widget _pdfDivider() =>
      pw.Divider(color: _line, borderStyle: pw.BorderStyle.dashed);

  pw.Widget _pdfField(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 8)),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      );

  pw.Widget _pdfRow(String label, String value) => pw.Row(
        children: [
          pw.SizedBox(
            width: 95,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: _muted, fontSize: 9),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      );

  Future<void> downloadImage(Map<String, dynamic> tx) async {
    final logo = base64Encode(
      (await rootBundle.load(_logoPath)).buffer.asUint8List(),
    );
    final barcode = base64Encode(
      utf8.encode(
        Barcode.code128().toSvg(
          _barcodeData(tx),
          width: 640,
          height: 150,
          drawText: false,
        ),
      ),
    );
    final svg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1350" viewBox="0 0 1080 1350">
<rect width="1080" height="1350" fill="#F6F7FA"/>
<rect x="180" y="80" width="720" height="1190" rx="38" fill="#FFFFFF"/>
<image href="data:image/png;base64,$logo" x="474" y="130" width="132" height="132"/>
<text x="540" y="330" text-anchor="middle" font-family="Arial,sans-serif" font-size="46" font-weight="700" fill="#1C202D">Thank you for giving!</text>
<text x="540" y="378" text-anchor="middle" font-family="Arial,sans-serif" font-size="24" fill="#737887">Your gift has been received successfully.</text>
${_svgLine(440)}
${_svgField(510, 240, 'RECEIPT ID', _reference(tx))}
${_svgField(510, 650, 'AMOUNT', _amount(tx))}
${_svgField(640, 240, 'DATE &amp; TIME', _date(tx))}
<rect x="230" y="720" width="620" height="216" rx="24" fill="#F6F7FA"/>
${_svgRow(778, 'Giving type', _label(tx['giving_type']))}
${_svgRow(838, 'Payment source', _source(tx))}
${_svgRow(898, 'Status', _label(tx['status']))}
${_svgLine(995)}
<image href="data:image/svg+xml;base64,$barcode" x="220" y="1040" width="640" height="130"/>
<text x="540" y="1195" text-anchor="middle" font-family="Arial,sans-serif" font-size="17" letter-spacing="3" fill="#737887">${_xml(_reference(tx))}</text>
<text x="540" y="1232" text-anchor="middle" font-family="Arial,sans-serif" font-size="17" font-weight="700" fill="#7C3FB2">Wisdom Power Christian Centre</text>
</svg>''';
    _download(
      Uint8List.fromList(utf8.encode(svg)),
      'wpcc-receipt-${_safeRef(tx)}.svg',
      'image/svg+xml',
    );
  }

  String _svgLine(int y) =>
      '<line x1="240" y1="$y" x2="840" y2="$y" stroke="#D9DCE4" stroke-width="3" stroke-dasharray="14 14"/>';

  String _svgField(int y, int x, String label, String value) =>
      '<text x="$x" y="$y" font-family="Arial,sans-serif" font-size="18" letter-spacing="2" fill="#737887">$label</text>'
      '<text x="$x" y="${y + 43}" font-family="Arial,sans-serif" font-size="28" font-weight="700" fill="#1C202D">${_xml(value)}</text>';

  String _svgRow(int y, String label, String value) =>
      '<text x="270" y="$y" font-family="Arial,sans-serif" font-size="21" fill="#737887">${_xml(label)}</text>'
      '<text x="480" y="$y" font-family="Arial,sans-serif" font-size="21" font-weight="600" fill="#1C202D">${_xml(value)}</text>';

  String _amount(Map<String, dynamic> tx) {
    final kobo = int.tryParse(tx['amount_kobo']?.toString() ?? '') ?? 0;
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    ).format(kobo / 100);
  }

  String _date(Map<String, dynamic> tx) {
    final raw = tx['paid_at'] ?? tx['initiated_at'] ?? tx['created_at'];
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return '—';
    return DateFormat('d MMM yyyy · h:mm a').format(
      date.toUtc().add(const Duration(hours: 1)),
    );
  }

  String _reference(Map<String, dynamic> tx) =>
      tx['paystack_reference']?.toString() ??
      tx['internal_reference']?.toString() ??
      '—';

  String _source(Map<String, dynamic> tx) =>
      tx['source_summary']?.toString() ??
      tx['payment_channel']?.toString() ??
      'Paystack';

  String _barcodeData(Map<String, dynamic> tx) {
    final value = _reference(tx).replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    return value.isEmpty || value == '—' ? 'WPCC-RECEIPT' : value;
  }

  String _label(dynamic value) => (value?.toString() ?? '—')
      .replaceAll('_', ' ')
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');

  String _safeRef(Map<String, dynamic> tx) =>
      _reference(tx).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');

  String _xml(String value) =>
      const HtmlEscape(HtmlEscapeMode.element).convert(value);

  void _download(Uint8List bytes, String filename, String mime) {
    final anchor = web.HTMLAnchorElement()
      ..href = 'data:$mime;base64,${base64Encode(bytes)}'
      ..download = filename;
    anchor.click();
  }
}
