import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import 'profile_repository.dart';
import 'classes_page.dart';

class QueryPage extends StatefulWidget {
  const QueryPage({super.key});
  @override
  State<QueryPage> createState() => _QueryPageState();
}

class _QueryPageState extends State<QueryPage> {
  final repo = ProfileRepository();
  final title = TextEditingController();
  final details = TextEditingController();
  final titleFocus = FocusNode();
  final detailsFocus = FocusNode();
  bool busy = false;
  String? message, titleError, detailsError;
  @override
  void dispose() {
    title.dispose();
    details.dispose();
    titleFocus.dispose();
    detailsFocus.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final shortTitle = title.text.trim().length < 3;
    final shortDetails = details.text.trim().length < 10;
    if (shortTitle || shortDetails) {
      setState(() {
        message = null;
        titleError = shortTitle
            ? 'Enter a subject with at least 3 characters.'
            : null;
        detailsError = shortDetails
            ? 'Add at least 10 characters of detail.'
            : null;
      });
      (shortTitle ? titleFocus : detailsFocus).requestFocus();
      return;
    }
    setState(() {
      busy = true;
      message = null;
      titleError = null;
      detailsError = null;
    });
    try {
      await repo.submitQuery(
        title: title.text.trim(),
        details: details.text.trim(),
      );
      if (mounted) {
        title.clear();
        details.clear();
        setState(() => message = 'Your query has been submitted.');
      }
    } catch (_) {
      if (mounted) setState(() => message = 'Unable to submit your query.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          const ProfileTabs(index: 2),
          const SizedBox(height: 34),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(PhosphorIcons.question(), size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            'How can we help?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          Text(
            'Send a query to the appropriate WPCC leadership team. You can review responses from your profile history.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WpccColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: title,
            focusNode: titleFocus,
            maxLength: 100,
            onChanged: (_) {
              if (titleError != null) setState(() => titleError = null);
            },
            decoration: InputDecoration(
              labelText: 'Subject',
              errorText: titleError,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: details,
            focusNode: detailsFocus,
            maxLines: 8,
            maxLength: 2000,
            onChanged: (_) {
              if (detailsError != null) setState(() => detailsError = null);
            },
            decoration: InputDecoration(
              labelText: 'Details',
              hintText: 'Describe your question or concern...',
              errorText: detailsError,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: busy ? null : submit,
            style: FilledButton.styleFrom(
              backgroundColor: WpccColors.primaryDeep,
              minimumSize: const Size.fromHeight(50),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit query'),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                message!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: WpccColors.inkSoft),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
