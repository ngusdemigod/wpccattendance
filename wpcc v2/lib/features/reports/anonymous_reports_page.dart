import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/member_material.dart';
import '../../core/theme/member_theme.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_glass.dart';

/// Widest readable column for the report form on tablets.
const double _formWidth = 640;
const int _minBodyLength = 20;
const int _stepCount = 3;

class AnonymousReportsPage extends StatefulWidget {
  const AnonymousReportsPage({super.key, this.rpc});
  final Future<dynamic> Function(String, Map<String, dynamic>)? rpc;
  @override
  State<AnonymousReportsPage> createState() => _AnonymousReportsPageState();
}

class _AnonymousReportsPageState extends State<AnonymousReportsPage> {
  final body = TextEditingController();
  final bodyFocus = FocusNode();
  final scroll = ScrollController();
  Future<dynamic> _rpc(String name, {Map<String, dynamic>? params}) =>
      widget.rpc?.call(name, params ?? {}) ??
      Supabase.instance.client.rpc(name, params: params);
  List<String> destinations = [];
  List<Map<String, dynamic>> reports = [];
  String? destination, error, submitError, submittedId;
  bool loading = true,
      loaded = false,
      busy = false,
      inbox = false,
      consent = false,
      canReview = false,
      copied = false;
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
    bodyFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    body.dispose();
    bodyFocus.dispose();
    scroll.dispose();
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
        loaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Reports are unavailable. Please retry.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool get _bodyReady => body.text.trim().length >= _minBodyLength;
  bool get _canSubmit =>
      !busy && consent && destination != null && _bodyReady;

  Future<void> _submit() async {
    if (busy ||
        destination == null ||
        !consent ||
        body.text.trim().length < _minBodyLength) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      error = null;
      submitError = null;
    });
    try {
      pendingSubmission ??= {
        'p_destination': destination,
        'p_body': body.text,
        'p_retry_key': retryKey,
      };
      final id =
          await _rpc('community_submit_anonymous', params: pendingSubmission);
      if (!mounted) return;
      setState(() {
        body.clear();
        pendingSubmission = null;
        retryKey = _newKey();
        consent = false;
        submittedId = id.toString();
        copied = false;
      });
      if (scroll.hasClients) {
        scroll.animateTo(0,
            duration: AppMotion.duration(context, AppMotion.page),
            curve: AppMotion.curve);
      }
      await _load();
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => submitError = e.code == '54000'
            ? 'Daily limit reached. Please try tomorrow.'
            : 'Submission could not be confirmed. Retry with the same report.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => submitError =
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

  Future<void> _copyReference() async {
    final id = submittedId;
    if (id == null) return;
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) setState(() => copied = true);
  }

  int get _stepsDone =>
      (destination != null ? 1 : 0) + (_bodyReady ? 1 : 0) + (consent ? 1 : 0);

  String get _nextHint {
    if (destination == null) return 'Next: choose who receives your report.';
    if (!_bodyReady) return 'Next: describe what happened.';
    if (!consent) return 'Next: confirm the privacy note.';
    return 'Ready to submit.';
  }

  EdgeInsets _padding(BuildContext context) {
    final base = memberPagePadding(context, bottom: 24);
    final extra = (MediaQuery.sizeOf(context).width - _formWidth) / 2;
    final side = extra > base.left ? extra : base.left;
    return EdgeInsets.fromLTRB(side, base.top, side, base.bottom);
  }

  @override
  Widget build(BuildContext context) {
    final locked = busy || pendingSubmission != null;
    final firstLoad = loading && !loaded;
    final formVisible = !inbox &&
        !firstLoad &&
        destinations.isNotEmpty &&
        submittedId == null;
    final padding = _padding(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: formVisible
          ? _SubmitBar(
              sidePadding: padding.left,
              done: _stepsDone,
              hint: _nextHint,
              busy: busy,
              enabled: _canSubmit,
              retrying: pendingSubmission != null && submitError != null,
              error: submitError,
              onSubmit: _submit)
          : null,
      body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                controller: scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: padding,
                children: [
                  MemberPageHeader(
                      title: 'Anonymous reports',
                      subtitle: inbox
                          ? 'Review reports sent to you.'
                          : 'Raise a concern with church reviewers.',
                      onBack: () => Navigator.maybePop(context)),
                  if (canReview) ...[
                    MemberTabSwitch(
                        labels: const ['My reports', 'Reviewer inbox'],
                        index: inbox ? 1 : 0,
                        onChanged: (i) {
                          if (busy || (i == 1) == inbox) return;
                          setState(() {
                            inbox = i == 1;
                            reports = [];
                          });
                          _load();
                        }),
                    const SizedBox(height: 20),
                  ],
                  if (firstLoad)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()))
                  else ...[
                    if (error != null)
                      MemberStatus(
                          message: error!,
                          icon: PhosphorIconsRegular.warningCircle,
                          onRetry: _load),
                    if (!inbox) ...[
                      AnimatedSwitcher(
                          duration:
                              AppMotion.duration(context, AppMotion.control),
                          switchInCurve: AppMotion.curve,
                          switchOutCurve: AppMotion.curve.flipped,
                          layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topCenter,
                                children: [...previous, if (current != null) current],
                              ),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: submittedId != null
                              ? _SuccessPanel(
                                  key: const ValueKey('report-success'),
                                  reference: submittedId!,
                                  copied: copied,
                                  onCopy: _copyReference,
                                  onDone: () => Navigator.maybePop(context),
                                  onAnother: () => setState(() {
                                        submittedId = null;
                                        copied = false;
                                      }))
                              : destinations.isEmpty
                                  ? (error == null
                                      ? const MemberStatus(
                                          key: ValueKey('report-empty'),
                                          icon: PhosphorIconsRegular.tray,
                                          message:
                                              'No reviewer destinations are available yet.')
                                      : const SizedBox.shrink(
                                          key: ValueKey('report-none')))
                                  : _buildForm(context, locked)),
                      const SizedBox(height: 28),
                    ],
                    MemberSectionHeader(
                        title: inbox ? 'Reports to review' : 'My submissions'),
                    if (loading && loaded)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()))
                    else if (reports.isEmpty)
                      MemberStatus(
                          icon: PhosphorIconsRegular.fileText,
                          message: inbox
                              ? 'No reports are waiting for review.'
                              : 'No reports yet. Reports you send will be listed here.')
                    else
                      for (final report in reports) _reportCard(context, report),
                  ],
                ],
              ))),
    );
  }

  Widget _buildForm(BuildContext context, bool locked) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final length = body.text.trim().length;
    final showError = !bodyFocus.hasFocus && length > 0 && length < _minBodyLength;
    final helper = pendingSubmission != null
        ? 'Locked while your submission is being confirmed.'
        : length == 0
            ? 'Write at least $_minBodyLength characters.'
            : length < _minBodyLength
                ? '${_minBodyLength - length} more characters needed.'
                : 'Minimum length reached.';
    return Column(
        key: const ValueKey('report-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrivacyNote(
              text:
                  'Your identity is hidden from reviewers but retained in restricted system records. Do not include names or details that identify you in your report.'),
          const SizedBox(height: 16),
          _StepCard(
              number: 1,
              title: 'Who should receive it',
              helper: 'Choose the reviewers for this report.',
              done: destination != null,
              child: Column(children: [
                for (var i = 0; i < destinations.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _DestinationOption(
                      label: destinations[i] == 'central'
                          ? 'Central reviewers'
                          : 'Branch reviewers',
                      selected: destination == destinations[i],
                      onTap: locked
                          ? null
                          : () => setState(() => destination = destinations[i])),
                ],
              ])),
          const SizedBox(height: 12),
          _StepCard(
              number: 2,
              title: 'What happened',
              helper: 'Share the facts in your own words. Leave out names or '
                  'details that could identify you.',
              done: _bodyReady,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Report details',
                            style: theme.textTheme.titleSmall)),
                    Semantics(
                        label: 'Report details',
                        child: TextField(
                            controller: body,
                            focusNode: bodyFocus,
                            enabled: !locked,
                            minLines: 5,
                            maxLines: 10,
                            maxLength: 5000,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                                filled: true,
                                hintText: 'Describe what happened',
                                helperText: showError ? null : helper,
                                helperMaxLines: 3,
                                errorText: showError
                                    ? 'Add at least $_minBodyLength characters so reviewers can act on it.'
                                    : null,
                                errorMaxLines: 3,
                                errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(
                                        color: colors.error, width: 1.5)),
                                focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(
                                        color: colors.error, width: 2))))),
                  ])),
          const SizedBox(height: 12),
          _StepCard(
              number: 3,
              title: 'Confirm privacy',
              helper: 'Check this before you submit.',
              done: consent,
              child: Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: consent,
                      title: const Text(
                          'I understand how my identity is protected.'),
                      onChanged: locked
                          ? null
                          : (v) => setState(() => consent = v ?? false)))),
        ]);
  }

  Widget _reportCard(BuildContext context, Map<String, dynamic> report) {
    final theme = Theme.of(context);
    final status = report['status'].toString();
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MemberGlass(
            radius: 20,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusLabel(status: status),
                      const SizedBox(height: 10),
                      SelectableText(report['body'].toString(),
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      SelectableText('Reference: ${report['id']}',
                          style: theme.textTheme.bodySmall),
                      if (inbox && status != 'Closed') ...[
                        const SizedBox(height: 4),
                        Wrap(spacing: 8, children: [
                          if (status == 'Submitted')
                            TextButton(
                                onPressed: busy
                                    ? null
                                    : () => _review(report, 'In review'),
                                child: const Text('Start review')),
                          TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _review(report, 'Closed'),
                              child: const Text('Close report')),
                        ]),
                      ],
                    ]))));
  }
}

/// Short reassurance that states exactly what the report flow does.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MemberGlass(
        radius: 20,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ExcludeSemantics(
                  child: Icon(PhosphorIconsRegular.shieldCheck, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('How your identity is handled',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(text, style: theme.textTheme.bodyMedium),
                  ])),
            ])));
  }
}

/// A numbered section. The number becomes a check once the step is complete.
class _StepCard extends StatelessWidget {
  const _StepCard(
      {required this.number,
      required this.title,
      required this.helper,
      required this.done,
      required this.child});
  final int number;
  final String title, helper;
  final bool done;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return MemberGlass(
        radius: 20,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                      header: true,
                      container: true,
                      excludeSemantics: true,
                      label:
                          'Step $number of $_stepCount, $title${done ? ', complete' : ''}. $helper',
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                                duration:
                                    AppMotion.duration(context, AppMotion.tab),
                                curve: AppMotion.curve,
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: done
                                        ? colors.primary
                                        : colors.onSurfaceVariant
                                            .withValues(alpha: .16)),
                                child: done
                                    ? Icon(PhosphorIconsBold.check,
                                        size: 14, color: colors.onPrimary)
                                    : Text('$number',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                color: colors.onSurface))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(title,
                                          style: theme.textTheme.titleMedium)),
                                  const SizedBox(height: 2),
                                  Text(helper, style: theme.textTheme.bodySmall),
                                ])),
                          ])),
                  const SizedBox(height: 14),
                  child,
                ])));
  }
}

class _DestinationOption extends StatelessWidget {
  const _DestinationOption(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        enabled: onTap != null,
        child: AppPressMotion(
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                        duration: AppMotion.duration(context, AppMotion.tab),
                        curve: AppMotion.curve,
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: selected
                                ? colors.primaryContainer
                                : Colors.transparent,
                            border: Border.all(
                                color: selected
                                    ? colors.onSurface
                                    : MemberMaterials.edge(context),
                                width: selected ? 1.5 : 1)),
                        child: Row(children: [
                          Icon(
                              selected
                                  ? PhosphorIconsFill.radioButton
                                  : PhosphorIconsRegular.circle,
                              size: 20,
                              color: selected
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(label,
                                  style: theme.textTheme.titleMedium)),
                        ]))))));
  }
}

/// Sticky action area: progress, the next missing step or a submit error, and
/// the primary button. It sits above the keyboard and the bottom safe area.
class _SubmitBar extends StatelessWidget {
  const _SubmitBar(
      {required this.sidePadding,
      required this.done,
      required this.hint,
      required this.busy,
      required this.enabled,
      required this.retrying,
      required this.error,
      required this.onSubmit});
  final double sidePadding;
  final int done;
  final String hint;
  final bool busy, enabled, retrying;
  final String? error;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
        decoration: BoxDecoration(
            color: MemberVisuals.page(context),
            border: Border(
                top: BorderSide(color: MemberMaterials.edge(context)))),
        child: SafeArea(
            top: false,
            child: Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 12),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (error != null)
                        Semantics(
                            liveRegion: true,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(PhosphorIconsRegular.warningCircle,
                                      size: 18, color: colors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(error!,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(color: colors.error))),
                                ]))
                      else ...[
                        TweenAnimationBuilder<double>(
                            tween: Tween(end: done / _stepCount),
                            duration:
                                AppMotion.duration(context, AppMotion.control),
                            curve: AppMotion.curve,
                            builder: (context, value, _) => ExcludeSemantics(
                                child: LinearProgressIndicator(
                                    value: value,
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                    color: colors.primary,
                                    backgroundColor: colors.onSurfaceVariant
                                        .withValues(alpha: .18)))),
                        const SizedBox(height: 8),
                        Text('$done of $_stepCount steps complete. $hint',
                            style: theme.textTheme.bodySmall),
                      ],
                      const SizedBox(height: 12),
                      AppPressMotion(
                          child: FilledButton(
                              onPressed: enabled ? onSubmit : null,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (busy)
                                      const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                    else
                                      Icon(
                                          retrying
                                              ? PhosphorIconsRegular
                                                  .arrowClockwise
                                              : PhosphorIconsRegular
                                                  .paperPlaneTilt,
                                          size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                        child: Text(busy
                                            ? 'Submitting...'
                                            : retrying
                                                ? 'Retry submission'
                                                : 'Submit report')),
                                  ]))),
                    ]))));
  }
}

/// Calm in-page confirmation that replaces the form after a successful send.
class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel(
      {super.key,
      required this.reference,
      required this.copied,
      required this.onCopy,
      required this.onDone,
      required this.onAnother});
  final String reference;
  final bool copied;
  final VoidCallback onCopy, onDone, onAnother;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
        liveRegion: true,
        child: MemberGlass(
            radius: 20,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ExcludeSemantics(
                          child: Icon(PhosphorIconsFill.checkCircle, size: 40)),
                      const SizedBox(height: 12),
                      Text('Report submitted',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                          'Thank you. Your report was sent to the reviewers. You can follow its status under My submissions.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Reference',
                                  style: theme.textTheme.bodySmall),
                              SelectableText(reference,
                                  style: theme.textTheme.titleSmall),
                            ])),
                        MemberIconButton(
                            icon: copied
                                ? PhosphorIconsRegular.check
                                : PhosphorIconsRegular.copy,
                            label: copied ? 'Reference copied' : 'Copy reference',
                            onPressed: onCopy),
                      ]),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: onDone, child: const Text('Done')),
                      TextButton(
                          onPressed: onAnother,
                          child: const Text('Write another report')),
                    ]))));
  }
}

/// Status shown as an icon and plain text, in the card header.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (status) {
      'Closed' => PhosphorIconsRegular.checkCircle,
      'In review' => PhosphorIconsRegular.hourglassMedium,
      _ => PhosphorIconsRegular.paperPlaneTilt,
    };
    return Row(children: [
      Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 8),
      Expanded(child: Text(status, style: theme.textTheme.titleSmall)),
    ]);
  }
}
