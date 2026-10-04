class ReceiptExportService {
  const ReceiptExportService();

  Future<void> downloadPdf(Map<String, dynamic> tx) =>
      Future.error(UnsupportedError('Receipt downloads require the web app.'));

  Future<void> downloadImage(Map<String, dynamic> tx) =>
      Future.error(UnsupportedError('Receipt downloads require the web app.'));
}
