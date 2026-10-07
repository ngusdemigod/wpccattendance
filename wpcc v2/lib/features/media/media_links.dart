import 'package:url_launcher/url_launcher.dart';

/// Opens an https link in the provider's own app or a new browser tab.
Future<void> openMediaLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && uri.scheme == 'https') {
    await launchUrl(uri,
        mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
  }
}
