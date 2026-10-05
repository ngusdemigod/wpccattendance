import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_glass.dart';

class AnonymousReportsPage extends StatefulWidget {
  const AnonymousReportsPage({super.key, this.rpc});
  final Future<dynamic> Function(String, Map<String, dynamic>)? rpc;
  @override
  State<AnonymousReportsPage> createState() => _AnonymousReportsPageState();
}

class _AnonymousReportsPageState extends State<AnonymousReportsPage> {
  final body = TextEditingController();
  Future<dynamic> _rpc(String name, {Map<String, dynamic>? params}) =>
      widget.rpc?.call(name, params ?? {}) ??
      Supabase.instance.client.rpc(name, params: params);
  List<String> destinations = [];
  List<Map<String, dynamic>> reports = [];
  String? destination, error;
  bool loading = true,
      busy = false,
      inbox = false,
      consent = false,
      canReview = false;
  String retryKey = _newKey();
  Map<String, dynamic>? pendingSubmission;
  static String _newKey() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final available =
          await _rpc('community_anonymous_destinations') as List;
      final access = await _rpc('community_report_access') as Map;
      final rows = await _rpc('community_anonymous_reports',
          params: {'p_inbox': inbox}) as List;
      if (!mounted) return;
      setState(() {
        destinations =
            available.map<String>((r) => r['destination'].toString()).toList();
        canReview = access['can_review'] == true;
        if (!destinations.contains(destination)) destination = null;
        reports = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Reports are unavailable. Please retry.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    if (busy || destination == null || !consent || body.text.trim().length < 20) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      pendingSubmission ??= {
        'p_destination': destination,
        'p_body': body.text,
        'p_retry_key': retryKey,
      };
      final id = await _rpc('community_submit_anonymous', params: pendingSubmission);
      if (!mounted) return;
      body.clear();
      pendingSubmission = null;
      retryKey = _newKey();
      consent = false;
      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Report submitted'),
                content: SelectableText('Reference: $id'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'))
                ],
              ));
      await _load();
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => error = e.code == '54000'
            ? 'Daily limit reached. Please try tomorrow.'
            : 'Submission could not be confirmed. Retry with the same report.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Connection interrupted. Retry to confirm your submission.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _review(Map<String, dynamic> report, String status) async {
    setState(() => busy = true);
    try {
      await _rpc('community_review_anonymous',
          params: {'p_id': report['id'], 'p_status': status});
      await _load();
    } catch (_) {
      if (mounted) {
        setState(
            () => error = 'Status could not be updated. Refresh and retry.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: memberPagePadding(context),
                  children: [
                    MemberPageHeader(
                        title: 'Anonymous reports',
                        onBack: () => Navigator.maybePop(context)),
                    if (canReview)
                      SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                                value: false, label: Text('My reports')),
                            ButtonSegment(
                                value: true, label: Text('Reviewer inbox')),
                          ],
                          selected: {
                            inbox
                          },
                          onSelectionChanged: busy
                              ? null
                              : (v) {
                                  setState(() {
                                    inbox = v.first;
                                    reports = [];
                                  });
                                  _load();
                                }),
                    const SizedBox(height: 20),
                    if (loading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      if (error != null)
                        MemberStatus(message: error!, onRetry: _load),
                      if (!inbox) ...[
                        const Text(
                            'Your identity is hidden from reviewers but retained in restricted system records. Do not include names or details that identify you in your report.'),
                        const SizedBox(height: 16),
                        if (destinations.isEmpty)
                          const MemberStatus(
                              message:
                                  'No reviewer destinations are available yet.')
                        else ...[
                          DropdownButtonFormField<String>(
                              key: ValueKey(destination),
                              initialValue: destination,
                              decoration:
                                  const InputDecoration(labelText: 'Send to'),
                              items: destinations
                                  .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d == 'central'
                                          ? 'Central reviewers'
                                          : 'Branch reviewers')))
                                  .toList(),
                              onChanged: busy || pendingSubmission != null
                                  ? null
                                  : (v) => setState(() => destination = v)),
                          const SizedBox(height: 16),
                          TextField(
                              controller: body,
                              enabled: !busy && pendingSubmission == null,
                              minLines: 5,
                              maxLines: 10,
                              maxLength: 5000,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                  labelText: 'Report',
                                  helperText: 'At least 20 characters')),
                          CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: consent,
                              title: const Text(
                                  'I understand how my identity is protected.'),
                              onChanged: busy || pendingSubmission != null
                                  ? null
                                  : (v) =>
                                      setState(() => consent = v ?? false)),
                          FilledButton(
                              onPressed: busy ||
                                      !consent ||
                                      destination == null ||
                                      body.text.trim().length < 20
                                  ? null
                                  : _submit,
                              child: Text(
                                  busy ? 'Submitting...' : 'Submit report')),
                        ],
                        const SizedBox(height: 24),
                        const MemberSectionHeader(title: 'My submissions'),
                      ],
                      if (reports.isEmpty)
                        const MemberStatus(message: 'No reports'),
                      for (final report in reports)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MemberGlass(
                                radius: 20,
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(report['status'].toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall),
                                          const SizedBox(height: 8),
                                          SelectableText(
                                              report['body'].toString()),
                                          const SizedBox(height: 12),
                                          SelectableText(
                                              'Reference: ${report['id']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          if (inbox &&
                                              report['status'] != 'Closed')
                                            Wrap(spacing: 8, children: [
                                              if (report['status'] ==
                                                  'Submitted')
                                                TextButton(
                                                    onPressed: busy
                                                        ? null
                                                        : () => _review(report,
                                                            'In review'),
                                                    child: const Text(
                                                        'Start review')),
                                              TextButton(
                                                  onPressed: busy
                                                      ? null
                                                      : () => _review(
                                                          report, 'Closed'),
                                                  child: const Text(
                                                      'Close report')),
                                            ]),
                                        ])))),
                    ],
                  ],
                ))),
      );
}
