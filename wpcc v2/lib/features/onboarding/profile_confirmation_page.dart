import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/initials_avatar.dart';
import '../profile/profile_repository.dart';
import 'onboarding_style.dart';
import 'prototype_auth_view.dart';
import 'profile_reward_screen.dart';

class ProfileConfirmationPage extends StatefulWidget {
  const ProfileConfirmationPage(
      {super.key, required this.onFinish, this.repository});
  final VoidCallback onFinish;
  final ProfileRepository? repository;
  @override
  State<ProfileConfirmationPage> createState() =>
      _ProfileConfirmationPageState();
}

class _ProfileConfirmationPageState extends State<ProfileConfirmationPage>
    with TickerProviderStateMixin {
  late final repo = widget.repository ?? ProfileRepository();
  final fields = List.generate(8, (_) => TextEditingController());
  final search = TextEditingController();
  late final entrance =
      AnimationController(vsync: this, duration: AppMotion.page);
  late final celebration = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  static const ease = AppMotion.curve;
  int step = 0;
  bool loading = true,
      busy = false,
      backwards = false,
      previouslyAwarded = false;
  bool awarded = false, pending = false, complete = false;
  String? error, avatar;
  List<Map<String, dynamic>> directory = [], linked = [];
  final selected = <String>{};
  Timer? polling;
  final errorKey = GlobalKey();
  bool errorRevealed = false;
  bool get reduced => MediaQuery.disableAnimationsOf(context);
  static const titles = [
    'Confirm your profile photo',
    'Confirm your full name',
    'Confirm your date of birth',
    'Confirm your phone number',
    'Confirm your address',
    'Confirm your occupation',
    'Confirm a close contact',
    'Confirm your departments'
  ];
  static const descriptions = [
    'Check the photo on your member record, or choose a newer one if it has changed.',
    'Verify we spelled your name correctly.',
    'Check that the date on your member record is correct before you continue.',
    'Review the number we have for you and update it if it is no longer current.',
    'Review your address and make any changes needed before continuing.',
    'Review the occupation on your member record and update it if it has changed.',
    'Check the trusted contact details we have for you, or update them if needed.',
    'Check the departments linked to your record and add any that are missing.',
  ];
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduced) {
      entrance.value = 1;
      celebration.value = 1;
    }
  }

  Future<void> load() async {
    try {
      repo.cache.invalidate('profile:');
      final p = await repo.profile();
      if (p == null) {
        throw StateError('Member record is unavailable. Please retry.');
      }
      final status = await repo.confirmationStatus();
      final choices = await repo.joinDirectory();
      if (!mounted) return;
      avatar = p['avatar']?.toString();
      for (final entry in {
        1: 'full_name',
        2: 'date_of_birth',
        3: 'phone',
        4: 'residential_address',
        5: 'occupation'
      }.entries) {
        fields[entry.key].text = p[entry.value]?.toString() ?? '';
      }
      final contact = p['emergency_contact']?.toString() ?? '';
      try {
        final parsed = jsonDecode(contact) as Map;
        fields[6].text = parsed['name']?.toString() ?? '';
        fields[7].text = parsed['phone']?.toString() ?? '';
      } catch (_) {
        final match =
            RegExp(r'^(.*?)\s*[|,;]\s*([+\d ()-]+)$').firstMatch(contact);
        fields[6].text = match?.group(1) ?? contact;
        fields[7].text = match?.group(2) ?? '';
      }
      linked = List<Map<String, dynamic>>.from((status['departments'] as List)
          .map((e) => Map<String, dynamic>.from(e)));
      directory = choices;
      previouslyAwarded = status['awarded'] == true;
      setState(() {
        loading = false;
        error = null;
      });
      if (!reduced) entrance.forward(from: 0);
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Your details could not be loaded. Please retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    polling?.cancel();
    entrance.dispose();
    celebration.dispose();
    search.dispose();
    for (final controller in fields) {
      controller.dispose();
    }
    super.dispose();
  }

  int digits(String value) => value.replaceAll(RegExp(r'\D'), '').length;
  bool get valid => switch (step) {
        0 => avatar?.isNotEmpty == true,
        1 => fields[1].text.trim().length >= 2,
        2 => DateTime.tryParse(fields[2].text) != null,
        3 => digits(fields[3].text) >= 7,
        4 => fields[4].text.trim().length >= 5,
        5 => fields[5].text.trim().length >= 2,
        6 => fields[6].text.trim().length >= 2 && digits(fields[7].text) >= 7,
        7 => linked.isNotEmpty || selected.isNotEmpty,
        _ => true,
      };
  void move(int next) {
    FocusScope.of(context).unfocus();
    setState(() {
      backwards = next < step;
      step = next;
      error = null;
    });
    entrance.value = reduced ? 1 : 0;
    if (!reduced) entrance.forward();
    if (next == 8) {
      celebration.value = reduced ? 1 : 0;
      if (!reduced) celebration.forward();
    }
  }

  Future<void> advance({bool skip = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!skip) {
        const keys = {
          1: 'full_name',
          2: 'date_of_birth',
          3: 'phone_number',
          4: 'residential_address',
          5: 'occupation'
        };
        if (keys.containsKey(step)) {
          await repo.saveConfirmation({keys[step]!: fields[step].text.trim()});
        }
        if (step == 6) {
          await repo.saveConfirmation({
            'emergency_contact': jsonEncode(
                {'name': fields[6].text.trim(), 'phone': fields[7].text.trim()})
          });
        }
        if (step == 7) {
          for (final id in selected.toList()) {
            await repo.requestDepartment(id);
            final d = directory.firstWhere((d) => d['department_id'] == id);
            linked.add({'id': id, 'name': d['name'], 'status': 'pending'});
            selected.remove(id);
          }
        }
      }
      if (step == 7) {
        await repo.checkConfirmationReward();
        final status = await repo.confirmationStatus();
        complete = status['complete'] == true;
        awarded = status['awarded'] == true;
        pending = status['pending'] == true;
      }
      if (mounted) move(step + 1);
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'We could not save these details. Check them and try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> upload() async {
    if (busy) return;
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true);
    if (result == null || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final url = await repo.uploadAvatar(result.files.single);
      if (mounted) setState(() => avatar = url);
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Photo upload failed. Use a JPG, PNG or WebP under 5 MB, then retry.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void openReward() {
    if (previouslyAwarded || !complete) {
      widget.onFinish();
      return;
    }
    move(9);
    celebration.value = reduced ? 1 : 0;
    if (!reduced) {
      celebration.forward();
    }
    if (!awarded) {
      polling = Timer.periodic(const Duration(seconds: 15), (_) async {
        try {
          final status = await repo.confirmationStatus();
          if (!mounted) return;
          if (status['awarded'] == true) {
            polling?.cancel();
            setState(() {
              awarded = true;
              pending = false;
            });
            if (!reduced) celebration.forward(from: 0);
          }
        } catch (_) {
          /* Durable worker retries; leaving this screen never cancels the award. */
        }
      });
    }
  }

  // ---- Presentation -------------------------------------------------------

  /// Staggered entrance for one block of a step. Every block fades once and
  /// moves 16 logical pixels in the direction of travel; nothing is nested.
  Widget enter(Widget child, double begin, double end) => AnimatedBuilder(
      animation: entrance,
      child: child,
      builder: (context, child) {
        final t = ease.transform(Interval(begin, end).transform(entrance.value));
        return Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset((backwards ? -16 : 16) * (1 - t), 0),
                child: child));
      });

  Widget profilePhoto(double size) => Container(
      padding: const EdgeInsets.all(Onb.s4),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Onb.inkAlpha(.22), width: 1.5)),
      child: avatar?.isNotEmpty == true
          ? InitialsAvatar(initials: 'WP', imageUrl: avatar, size: size)
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Onb.inkAlpha(.08)),
              padding: EdgeInsets.all(size * .26),
              child: Image.asset('assets/images/onboarding_logo.png',
                  semanticLabel: 'WPCC logo')));

  Widget field(int index, String label,
          {String? hint,
          String? helper,
          TextInputType? keyboard,
          int lines = 1,
          bool readOnly = false,
          VoidCallback? onTap}) =>
      OnbField(
          label: label,
          controller: fields[index],
          hint: hint,
          helper: helper,
          keyboard: keyboard,
          lines: lines,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: (_) => setState(() {}));

  Widget form(bool short) {
    switch (step) {
      case 0:
        return Column(children: [
          Center(child: profilePhoto(short ? 112 : 136)),
          const SizedBox(height: Onb.s24),
          Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: OnbSecondaryButton(
                      label: busy ? 'Uploading…' : 'Choose photo',
                      icon: PhosphorIcons.camera(),
                      onPressed: busy ? null : upload))),
        ]);
      case 1:
        return field(1, 'Full name',
            hint: 'Enter your full name', keyboard: TextInputType.name);
      case 2:
        return field(2, 'Date of birth',
            hint: 'Select your date of birth',
            helper: 'Tap to choose a date.',
            readOnly: true, onTap: () async {
          final now = DateTime.now();
          final date = DateTime.tryParse(fields[2].text);
          final picked = await showDatePicker(
              context: context,
              initialDate: date != null && date.isBefore(now)
                  ? date
                  : DateTime(now.year - 18),
              firstDate: DateTime(1900),
              lastDate: now);
          if (picked != null && mounted) {
            setState(() =>
                fields[2].text = picked.toIso8601String().substring(0, 10));
          }
        });
      case 3:
        return field(3, 'Phone number',
            hint: '+234 801 234 5678', keyboard: TextInputType.phone);
      case 4:
        return field(4, 'Address',
            hint: 'Enter your address',
            keyboard: TextInputType.streetAddress,
            lines: 4);
      case 5:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          field(5, 'Occupation',
              hint: 'Enter your occupation',
              helper: 'Separate several with commas.'),
          const SizedBox(height: Onb.s16),
          Wrap(
              spacing: Onb.s8,
              runSpacing: Onb.s8,
              children: [
                'Entrepreneur',
                'Engineer',
                'Doctor',
                'Fashion designer'
              ].map((value) {
                final parts = fields[5]
                    .text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toSet();
                final active = parts.contains(value);
                return OnbChip(
                    label: value,
                    selected: active,
                    onTap: () => setState(() {
                          active ? parts.remove(value) : parts.add(value);
                          fields[5].text = parts.join(', ');
                        }));
              }).toList())
        ]);
      case 6:
        return Column(children: [
          field(6, 'Contact name',
              hint: 'Enter contact name', keyboard: TextInputType.name),
          const SizedBox(height: Onb.s20),
          field(7, 'Contact phone number',
              hint: '+234 801 234 5678', keyboard: TextInputType.phone)
        ]);
      case 7:
        return departments();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget departmentChip(String name,
          {bool pending = false, VoidCallback? onRemove}) =>
      OnbChip(
          label: name,
          selected: onRemove != null,
          onTap: onRemove,
          semanticLabel: onRemove != null
              ? 'Remove $name'
              : pending
                  ? '$name, pending approval'
                  : name,
          trailing: onRemove != null
              ? Icon(PhosphorIcons.x(), size: 16, color: Onb.ink)
              : pending
                  ? Text('Pending',
                      style: Onb.body(12,
                              alpha: 1, weight: FontWeight.w600, height: 1.2)
                          .copyWith(color: Onb.accentLight))
                  : null);

  Widget departments() {
    final linkedIds = linked.map((d) => d['id']).toSet();
    final options = directory
        .where((d) =>
            !linkedIds.contains(d['department_id']) &&
            !selected.contains(d['department_id']) &&
            d['name']
                .toString()
                .toLowerCase()
                .contains(search.text.toLowerCase()))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OnbField(
          label: 'Search departments',
          controller: search,
          hint: 'Type a department name',
          onChanged: (_) => setState(() {}),
          prefix: Icon(PhosphorIcons.magnifyingGlass(),
              size: 20, color: Onb.inkAlpha(.6))),
      if (linked.isNotEmpty || selected.isNotEmpty) ...[
        const SizedBox(height: Onb.s24),
        Text('Your departments', style: Onb.label()),
        const SizedBox(height: Onb.s12),
        Wrap(spacing: Onb.s8, runSpacing: Onb.s8, children: [
          for (final d in linked)
            departmentChip('${d['name']}', pending: d['status'] == 'pending'),
          for (final id in selected)
            departmentChip(
                directory
                    .firstWhere((d) => d['department_id'] == id)['name']
                    .toString(),
                onRemove: () => setState(() => selected.remove(id))),
        ]),
      ],
      const SizedBox(height: Onb.s24),
      Text('Available departments', style: Onb.label()),
      const SizedBox(height: Onb.s12),
      if (options.isEmpty)
        Text('No matching departments',
            style: Onb.body(13, alpha: .64))
      else
        LayoutBuilder(
            builder: (context, c) => Wrap(
                spacing: Onb.s12,
                runSpacing: Onb.s12,
                children: options
                    .map((d) => SizedBox(
                        width: (c.maxWidth - Onb.s12) / 2,
                        child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                minimumSize:
                                    const Size.fromHeight(Onb.minTarget + 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Onb.s12, vertical: Onb.s12),
                                backgroundColor: Onb.inkAlpha(.05),
                                foregroundColor: Onb.ink,
                                side: BorderSide(color: Onb.inkAlpha(.2)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        Onb.radiusControl))),
                            onPressed: () => setState(() =>
                                selected.add(d['department_id'] as String)),
                            child: Row(children: [
                              Expanded(
                                  child: Text(d['name'].toString(),
                                      style: Onb.body(13,
                                          alpha: 1,
                                          weight: FontWeight.w500,
                                          height: 1.25))),
                              const SizedBox(width: Onb.s8),
                              Icon(PhosphorIcons.plus(),
                                  size: 16, color: Onb.inkAlpha(.7))
                            ]))))
                    .toList())),
      const SizedBox(height: Onb.s16),
      const OnbMessage('New departments are submitted for approval.'),
    ]);
  }

  Widget background(int photo) => Stack(fit: StackFit.expand, children: [
        Transform.scale(
            scale: 1.07,
            child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Image.asset('assets/images/onboarding_$photo.jpg',
                    fit: BoxFit.cover))),
        const OnbScrim(base: .38, bottom: .9),
      ]);

  Widget backButton() => OnbBackButton(
      tooltip: step == 0 ? 'Back to sign in' : 'Back',
      onPressed: busy
          ? null
          : () {
              if (step == 0) {
                Supabase.instance.client.auth.signOut();
              } else {
                move(step - 1);
              }
            });

  /// Placeholder shapes while the member record loads. No spinner.
  Widget skeleton(double side) {
    Widget bar(double? width, double height, [double radius = 8]) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: Onb.inkAlpha(.09),
            borderRadius: BorderRadius.circular(radius)));
    return Semantics(
        label: 'Loading your details',
        child: Padding(
            padding: EdgeInsets.fromLTRB(side, 92, side, 0),
            child: ExcludeSemantics(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  bar(260, 32),
                  const SizedBox(height: Onb.s12),
                  bar(180, 32),
                  const SizedBox(height: Onb.s20),
                  bar(null, 14),
                  const SizedBox(height: Onb.s8),
                  bar(220, 14),
                  const SizedBox(height: Onb.s32),
                  bar(96, 12),
                  const SizedBox(height: Onb.s8),
                  bar(null, 56, Onb.radiusControl),
                ]))));
  }

  Widget topBar(double side) => Padding(
      padding: EdgeInsets.fromLTRB(side, Onb.s12, side, Onb.s12),
      child: Row(children: [
        backButton(),
        Expanded(
            child: Center(
                child: step < 8
                    ? Text(Onb.stepLabel(step + 1, 8),
                        style: Onb.label(alpha: .78))
                    : const SizedBox.shrink())),
        step < 8
            ? OnbTextAction(
                label: 'Skip', onPressed: busy ? null : () => advance(skip: true))
            : const SizedBox(width: Onb.minTarget),
      ]));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final short = size.height <= 780;
    final side = size.width >= 600
        ? math.max(32.0, (size.width - 600) / 2)
        : Onb.gutter(size.width, short: short);
    final photo = PrototypeAuthScope.of(context)?.photo ?? 0;
    final headingSize = size.width <= 370
        ? 28.0
        : short
            ? 30.0
            : 32.0;
    if (error == null) {
      errorRevealed = false;
    } else if (!errorRevealed) {
      errorRevealed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = errorKey.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(target,
              duration: AppMotion.duration(context, AppMotion.control),
              curve: AppMotion.curve);
        }
      });
    }
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !busy && step > 0 && step < 9) move(step - 1);
        },
        child: Scaffold(
            backgroundColor: Onb.canvas,
            body: Stack(fit: StackFit.expand, children: [
              if (step < 9) background(photo),
              if (step == 9)
                reward(short)
              else
                SafeArea(
                    child: loading
                        ? skeleton(side)
                        : Column(children: [
                            topBar(side),
                            if (step < 8)
                              Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: side),
                                  child:
                                      OnbStepSegments(current: step + 1, total: 8)),
                            Expanded(
                                child: SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(side,
                                        short ? Onb.s20 : Onb.s32, side, Onb.s24),
                                    child: step == 8
                                        ? enter(done(short), 0, 1)
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                                enter(
                                                    Text(titles[step],
                                                        style: Onb.heading(
                                                            headingSize)),
                                                    0,
                                                    .7),
                                                const SizedBox(height: Onb.s12),
                                                enter(
                                                    ConstrainedBox(
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxWidth: 480),
                                                        child: Text(
                                                            descriptions[step],
                                                            style: Onb.body(
                                                                short ? 14 : 15))),
                                                    .1,
                                                    .85),
                                                SizedBox(
                                                    height: short
                                                        ? Onb.s24
                                                        : Onb.s32),
                                                enter(form(short), .2, 1),
                                                if (error != null)
                                                  Padding(
                                                      key: errorKey,
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: Onb.s16),
                                                      child: OnbMessage(error!,
                                                          isError: true)),
                                              ]))),
                            Padding(
                                padding: EdgeInsets.fromLTRB(side, Onb.s8, side,
                                    short ? Onb.s12 : Onb.s16),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OnbPrimaryButton(
                                          label: busy
                                              ? 'Saving…'
                                              : step == 8
                                                  ? 'Continue to WPCC Community'
                                                  : 'Continue',
                                          onPressed: busy
                                              ? null
                                              : step == 8
                                                  ? openReward
                                                  : valid
                                                      ? () => advance()
                                                      : null),
                                      if (error != null &&
                                          avatar == null &&
                                          fields[1].text.isEmpty)
                                        OnbTextAction(
                                            label: 'Retry loading details',
                                            onPressed: load),
                                    ])),
                          ])),
            ])));
  }

  Widget done(bool short) => Column(children: [
        SizedBox(height: short ? Onb.s8 : Onb.s32),
        AnimatedBuilder(
            animation: celebration,
            builder: (context, child) {
              final t = Curves.easeOutBack
                  .transform((celebration.value * 2.4).clamp(0, 1));
              return Transform.scale(scale: .72 + .28 * t, child: child);
            },
            child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(alignment: Alignment.center, children: [
                  AnimatedBuilder(
                      animation: celebration,
                      builder: (context, _) => CustomPaint(
                          size: const Size(180, 180),
                          painter: _CelebrationPainter(celebration.value,
                              burst: true))),
                  Container(
                      padding: const EdgeInsets.all(Onb.s8),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Onb.inkAlpha(.08),
                          border: Border.all(color: Onb.inkAlpha(.22))),
                      child: InitialsAvatar(
                          initials: 'WP', imageUrl: avatar, size: 96)),
                ]))),
        SizedBox(height: short ? Onb.s24 : Onb.s32),
        Text('Details Verified',
            textAlign: TextAlign.center, style: Onb.heading(short ? 32 : 36)),
        const SizedBox(height: Onb.s12),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
                'Thank you for verifying your details. This helps us reach out and serve you better.',
                textAlign: TextAlign.center,
                style: Onb.body(15))),
      ]);
  Widget reward(bool short) =>
      ProfileRewardScreen(awarded: awarded, onClose: widget.onFinish);
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.progress, {required this.burst});
  final double progress;
  final bool burst;
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    const colors = [
      Color(0xffad7cff),
      Color(0xff70d7e9),
      Color(0xffff96cb),
      Color(0xffffdf80)
    ];
    for (var i = 0; i < 28; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = 40 + random.nextDouble() * 55;
      final p = burst
          ? Offset(size.width / 2 + math.cos(angle) * distance * progress,
              size.height / 2 + math.sin(angle) * distance * progress)
          : Offset(random.nextDouble() * size.width,
              ((random.nextDouble() - progress * .15) % 1) * size.height);
      final opacity = burst
          ? (1 - progress).clamp(0.0, 1.0)
          : .2 + random.nextDouble() * .35;
      canvas.drawCircle(p, burst ? 2.5 : 1 + random.nextDouble(),
          Paint()..color = colors[i % 4].withValues(alpha: opacity));
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) =>
      old.progress != progress || old.burst != burst;
}
