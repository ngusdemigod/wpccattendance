import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:barcode/barcode.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The fields shown on a giving receipt, taken only from the transaction row.
///
/// Nothing here is invented: a missing value is shown as an em dash.
class ReceiptData {
  const ReceiptData({
    required this.reference,
    required this.amount,
    required this.dateTime,
    required this.givingType,
    required this.paymentSource,
    required this.status,
    required this.kind,
  });

  factory ReceiptData.fromTransaction(Map<String, dynamic> tx) {
    final kobo = num.tryParse(tx['amount_kobo']?.toString() ?? '');
    final raw = tx['paid_at'] ?? tx['initiated_at'] ?? tx['created_at'];
    final date = DateTime.tryParse(raw?.toString() ?? '');
    final status = tx['status']?.toString() ?? '';
    return ReceiptData(
      reference: tx['paystack_reference']?.toString() ??
          tx['internal_reference']?.toString() ??
          '—',
      amount: kobo == null
          ? '—'
          : NumberFormat('#,##0.00', 'en').format(kobo / 100),
      dateTime: date == null
          ? '—'
          : DateFormat('d MMM yyyy · h:mm a')
              .format(date.toUtc().add(const Duration(hours: 1))),
      givingType: _label(tx['giving_type']),
      paymentSource: tx['source_summary']?.toString() ??
          tx['payment_channel']?.toString() ??
          'Paystack',
      status: status == 'initialized' ? 'Processing' : _label(tx['status']),
      kind: status == 'successful'
          ? ReceiptKind.successful
          : const ['pending', 'initialized', 'processing'].contains(status)
              ? ReceiptKind.pending
              : ReceiptKind.unsuccessful,
    );
  }

  final String reference, amount, dateTime, givingType, paymentSource, status;
  final ReceiptKind kind;

  bool get hasAmount => amount != '—';

  String get title => switch (kind) {
        ReceiptKind.successful => 'Thank you for giving!',
        ReceiptKind.pending => 'Payment pending',
        ReceiptKind.unsuccessful => 'Payment not completed',
      };

  String get subtitle => switch (kind) {
        ReceiptKind.successful => 'Your gift has been received successfully.',
        ReceiptKind.pending => 'This payment has not been confirmed yet.',
        ReceiptKind.unsuccessful => 'This payment did not go through.',
      };

  String get fileStem =>
      'wpcc-receipt-${reference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-')}';

  /// Code 128 only encodes printable ASCII.
  String get barcodeData {
    final value = reference.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    return value.isEmpty ? 'WPCC-RECEIPT' : value;
  }

  static String _label(dynamic value) => (value?.toString() ?? '—')
      .replaceAll('_', ' ')
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}

enum ReceiptKind { successful, pending, unsuccessful }

const _logoPath = 'assets/images/wpcc_logo.png';
const _fontRegularPath = 'assets/DMSans-Regular.ttf';
const _fontBoldPath = 'assets/DMSans-Bold.ttf';

/// The Naira sign is missing from DM Sans (and from the PDF base fonts), so it
/// is drawn as vector strokes rather than risking a missing-glyph box.
///
/// Returns the stroke segments of the sign in a unit box where x runs 0..1
/// left to right and y runs 0..1 top to bottom.
const List<(Offset, Offset)> _nairaStrokes = [
  (Offset(.12, 0), Offset(.12, 1)),
  (Offset(.88, 0), Offset(.88, 1)),
  (Offset(.12, 0), Offset(.88, 1)),
  (Offset(-.04, .38), Offset(1.04, .38)),
  (Offset(-.04, .62), Offset(1.04, .62)),
];

/// Builds a one page A4 PDF receipt.
Future<Uint8List> buildReceiptPdf(Map<String, dynamic> tx) async {
  final data = ReceiptData.fromTransaction(tx);
  final logo =
      pw.MemoryImage((await rootBundle.load(_logoPath)).buffer.asUint8List());
  final regular = pw.Font.ttf(await rootBundle.load(_fontRegularPath));
  final bold = pw.Font.ttf(await rootBundle.load(_fontBoldPath));
  final document = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    title: 'WPCC giving receipt ${data.reference}',
    author: 'Wisdom Power Christian Centre',
  )..addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(
          color: _pdfSurface,
          alignment: pw.Alignment.center,
          child: _pdfReceipt(data, logo),
        ),
      ),
    );
  return Uint8List.fromList(await document.save());
}

const _pdfInk = PdfColor.fromInt(0xFF1C202D);
const _pdfMuted = PdfColor.fromInt(0xFF737887);
const _pdfLine = PdfColor.fromInt(0xFFE4E6EC);
const _pdfSurface = PdfColor.fromInt(0xFFF6F7FA);
const _pdfPurple = PdfColor.fromInt(0xFF7C3FB2);

pw.Widget _pdfReceipt(ReceiptData data, pw.ImageProvider logo) => pw.Container(
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
          pw.Text(data.title,
              style: pw.TextStyle(
                  color: _pdfInk,
                  fontSize: 23,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 7),
          pw.Text(data.subtitle,
              style: const pw.TextStyle(color: _pdfMuted, fontSize: 11)),
          pw.SizedBox(height: 24),
          _pdfDivider(),
          pw.SizedBox(height: 22),
          pw.Text('AMOUNT',
              style: const pw.TextStyle(color: _pdfMuted, fontSize: 8)),
          pw.SizedBox(height: 6),
          _pdfAmount(data),
          pw.SizedBox(height: 20),
          pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: _pdfField('RECEIPT ID', data.reference)),
          pw.SizedBox(height: 16),
          pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: _pdfField('DATE & TIME', data.dateTime)),
          pw.SizedBox(height: 18),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
                color: _pdfSurface, borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Column(children: [
              _pdfRow('Giving type', data.givingType),
              pw.SizedBox(height: 9),
              _pdfRow('Payment source', data.paymentSource),
              pw.SizedBox(height: 9),
              _pdfRow('Status', data.status),
            ]),
          ),
          pw.SizedBox(height: 22),
          _pdfDivider(),
          pw.SizedBox(height: 22),
          pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: data.barcodeData,
            width: 270,
            height: 72,
            drawText: false,
            color: _pdfInk,
          ),
          pw.SizedBox(height: 8),
          pw.Text(data.reference,
              style: const pw.TextStyle(
                  color: _pdfMuted, fontSize: 8, letterSpacing: 1.2)),
          pw.SizedBox(height: 18),
          pw.Text('Wisdom Power Christian Centre',
              style: pw.TextStyle(
                  color: _pdfPurple,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated from a WPCC transaction record.',
              style: const pw.TextStyle(color: _pdfMuted, fontSize: 8)),
        ],
      ),
    );

pw.Widget _pdfDivider() =>
    pw.Divider(color: _pdfLine, borderStyle: pw.BorderStyle.dashed);

pw.Widget _pdfAmount(ReceiptData data) {
  const size = 26.0;
  final text = pw.Text(data.amount,
      style: pw.TextStyle(
          color: _pdfInk, fontSize: size, fontWeight: pw.FontWeight.bold));
  if (!data.hasAmount) return text;
  const markHeight = size * .72;
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.CustomPaint(
        size: const PdfPoint(markHeight * .8, markHeight),
        painter: (canvas, box) {
          canvas
            ..setStrokeColor(_pdfInk)
            ..setLineWidth(2.2);
          for (final (a, b) in _nairaStrokes) {
            canvas
              ..moveTo(a.dx * box.x, (1 - a.dy) * box.y)
              ..lineTo(b.dx * box.x, (1 - b.dy) * box.y)
              ..strokePath();
          }
        },
      ),
      pw.SizedBox(width: 5),
      text,
    ],
  );
}

pw.Widget _pdfField(String label, String value) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(color: _pdfMuted, fontSize: 8)),
        pw.SizedBox(height: 5),
        pw.Text(value,
            style: pw.TextStyle(
                color: _pdfInk, fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );

pw.Widget _pdfRow(String label, String value) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 95,
          child: pw.Text(label,
              style: const pw.TextStyle(color: _pdfMuted, fontSize: 9)),
        ),
        pw.Expanded(
          child: pw.Text(value,
              style: pw.TextStyle(
                  color: _pdfInk, fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );

// ---------------------------------------------------------------------------
// PNG

/// Width of the PNG receipt in pixels. The height follows the content.
const receiptImageWidth = 1080;

/// Renders the receipt as a PNG straight onto a canvas, so it never depends on
/// a widget being laid out or painted on screen.
Future<Uint8List> buildReceiptPng(Map<String, dynamic> tx) async {
  final data = ReceiptData.fromTransaction(tx);
  final codec = await ui.instantiateImageCodec(
      (await rootBundle.load(_logoPath)).buffer.asUint8List());
  final logo = (await codec.getNextFrame()).image;
  try {
    // Measure first so the card hugs its content, then paint for real.
    final measure = ui.PictureRecorder();
    final cardBottom = _paintReceipt(
        Canvas(measure), data, logo, receiptImageWidth.toDouble(), 0);
    measure.endRecording().dispose();

    final height = (cardBottom + 80).ceil();
    final recorder = ui.PictureRecorder();
    _paintReceipt(
        Canvas(recorder), data, logo, receiptImageWidth.toDouble(), cardBottom);
    final picture = recorder.endRecording();
    final image = await picture.toImage(receiptImageWidth, height);
    picture.dispose();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('The receipt image could not be encoded.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    logo.dispose();
    codec.dispose();
  }
}

const _ink = Color(0xFF1C202D);
const _muted = Color(0xFF737887);
const _rule = Color(0xFFD9DCE4);
const _surface = Color(0xFFF6F7FA);
const _purple = Color(0xFF7C3FB2);
const _fontFamily = 'DM Sans';

/// Paints the receipt and returns the y coordinate of the card's bottom edge.
/// [cardBottom] is 0 on the measuring pass.
double _paintReceipt(Canvas canvas, ReceiptData data, ui.Image logo,
    double width, double cardBottom) {
  const margin = 80.0;
  const cardLeft = 180.0;
  final cardWidth = width - cardLeft * 2;
  const inner = 50.0;
  final left = cardLeft + inner;
  final right = cardLeft + cardWidth - inner;
  final innerWidth = right - left;
  final centre = width / 2;

  if (cardBottom > 0) {
    canvas.drawRect(Rect.fromLTWH(0, 0, width, cardBottom + margin),
        Paint()..color = _surface);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(cardLeft, margin, cardLeft + cardWidth, cardBottom),
            const Radius.circular(38)),
        Paint()..color = const Color(0xFFFFFFFF));
  }

  double y = margin + 54;
  canvas.drawImageRect(
      logo,
      Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
      Rect.fromLTWH(centre - 66, y, 132, 132),
      Paint()..filterQuality = FilterQuality.high);
  y += 132 + 36;

  y += _text(canvas, data.title, Offset(centre, y),
      size: 46, bold: true, color: _ink, width: innerWidth + 60, center: true);
  y += 12;
  y += _text(canvas, data.subtitle, Offset(centre, y),
      size: 24, color: _muted, width: innerWidth + 60, center: true);
  y += 38;
  _dashed(canvas, left, right, y);
  y += 38;

  y += _text(canvas, 'AMOUNT', Offset(centre, y),
      size: 18, color: _muted, spacing: 2, width: innerWidth, center: true);
  y += 12;
  y += _amount(canvas, data, centre, y);
  y += 40;

  for (final (label, value) in [
    ('RECEIPT ID', data.reference),
    ('DATE & TIME', data.dateTime),
  ]) {
    y += _text(canvas, label, Offset(left, y),
        size: 18, color: _muted, spacing: 2, width: innerWidth);
    y += 10;
    y += _text(canvas, value, Offset(left, y),
        size: 28, bold: true, color: _ink, width: innerWidth, maxLines: 2);
    y += 32;
  }

  // Detail panel.
  const pad = 26.0;
  final rows = [
    ('Giving type', data.givingType),
    ('Payment source', data.paymentSource),
    ('Status', data.status),
  ];
  const labelWidth = 190.0;
  final valueWidth = innerWidth - pad * 2 - labelWidth;
  var panelHeight = pad * 2;
  final heights = <double>[];
  for (final (_, value) in rows) {
    final h =
        _measure(value, size: 21, bold: true, width: valueWidth, maxLines: 2);
    heights.add(h);
    panelHeight += h + 22;
  }
  panelHeight -= 22;
  if (cardBottom > 0) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, y, innerWidth, panelHeight),
            const Radius.circular(24)),
        Paint()..color = _surface);
  }
  var rowY = y + pad;
  for (var i = 0; i < rows.length; i++) {
    _text(canvas, rows[i].$1, Offset(left + pad, rowY),
        size: 21, color: _muted, width: labelWidth);
    _text(canvas, rows[i].$2, Offset(left + pad + labelWidth, rowY),
        size: 21, bold: true, color: _ink, width: valueWidth, maxLines: 2);
    rowY += heights[i] + 22;
  }
  y += panelHeight + 42;
  _dashed(canvas, left, right, y);
  y += 44;

  const barcodeWidth = 600.0, barcodeHeight = 110.0;
  if (cardBottom > 0) {
    final paint = Paint()..color = _ink;
    for (final element in Barcode.code128().make(data.barcodeData,
        width: barcodeWidth, height: barcodeHeight, drawText: false)) {
      if (element is BarcodeBar && element.black) {
        canvas.drawRect(
            Rect.fromLTWH(centre - barcodeWidth / 2 + element.left,
                y + element.top, element.width, element.height),
            paint);
      }
    }
  }
  y += barcodeHeight + 20;
  y += _text(canvas, data.reference, Offset(centre, y),
      size: 17, color: _muted, spacing: 3, width: innerWidth, center: true);
  y += 26;
  y += _text(canvas, 'Wisdom Power Christian Centre', Offset(centre, y),
      size: 19, bold: true, color: _purple, width: innerWidth, center: true);
  y += 8;
  y += _text(
      canvas, 'Generated from a WPCC transaction record.', Offset(centre, y),
      size: 16, color: _muted, width: innerWidth, center: true);
  return y + 54;
}

double _amount(Canvas canvas, ReceiptData data, double centre, double top) {
  const size = 64.0;
  final painter = _painter(data.amount,
      size: size, bold: true, color: _ink, width: 900, center: false);
  final height = painter.height;
  if (!data.hasAmount) {
    painter.paint(canvas, Offset(centre - painter.width / 2, top));
    return height;
  }
  const markHeight = size * .62;
  const markWidth = markHeight * .8;
  const gap = 14.0;
  final total = markWidth + gap + painter.width;
  final startX = centre - total / 2;
  final markTop = top + height / 2 - markHeight / 2;
  final paint = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  for (final (a, b) in _nairaStrokes) {
    canvas.drawLine(
        Offset(startX + a.dx * markWidth, markTop + a.dy * markHeight),
        Offset(startX + b.dx * markWidth, markTop + b.dy * markHeight),
        paint);
  }
  painter.paint(canvas, Offset(startX + markWidth + gap, top));
  return height;
}

void _dashed(Canvas canvas, double x1, double x2, double y) {
  final paint = Paint()
    ..color = _rule
    ..strokeWidth = 3;
  for (var x = x1; x < x2; x += 28) {
    canvas.drawLine(Offset(x, y), Offset(math.min(x + 14, x2), y), paint);
  }
}

TextPainter _painter(String text,
    {required double size,
    required Color color,
    required double width,
    bool bold = false,
    bool center = false,
    double spacing = 0,
    int maxLines = 1}) {
  return TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color,
            letterSpacing: spacing,
            height: 1.25)),
    textAlign: center ? TextAlign.center : TextAlign.start,
    textDirection: ui.TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: width);
}

double _measure(String text,
        {required double size,
        required double width,
        bool bold = false,
        int maxLines = 1}) =>
    _painter(text,
            size: size,
            color: _ink,
            width: width,
            bold: bold,
            maxLines: maxLines)
        .height;

/// Draws text with its top at [at].dy and returns the height used. When
/// [center] is true [at].dx is the horizontal centre.
double _text(Canvas canvas, String text, Offset at,
    {required double size,
    required Color color,
    required double width,
    bool bold = false,
    bool center = false,
    double spacing = 0,
    int maxLines = 1}) {
  final painter = _painter(text,
      size: size,
      color: color,
      width: width,
      bold: bold,
      center: center,
      spacing: spacing,
      maxLines: maxLines);
  painter.paint(
      canvas, Offset(center ? at.dx - painter.width / 2 : at.dx, at.dy));
  return painter.height;
}
