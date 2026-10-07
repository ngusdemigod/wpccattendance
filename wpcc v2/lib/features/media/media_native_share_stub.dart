/// Opens the system share sheet. Returns false when it is not available, so
/// the caller can fall back to copying the link.
Future<bool> nativeShare(
        {required String title, String? text, required String url}) async =>
    false;
