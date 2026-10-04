import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/initials_avatar.dart';
import '../profile/profile_repository.dart';
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
  TextStyle body(double size,
          {double alpha = 1, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmSans(
          fontSize: size,
          height: 1.42,
          letterSpacing: -size * .015,
          color: Colors.white.withValues(alpha: alpha),
          fontWeight: weight);
  TextStyle title(double size) => GoogleFonts.manrope(
      fontSize: size,
      height: .99,
      letterSpacing: -size * .055,
      fontWeight: FontWeight.w800,
      color: Colors.white);
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

  Widget action(String text, VoidCallback? onTap) => SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff151515),
              disabledBackgroundColor: Colors.white.withValues(alpha: .16),
              disabledForegroundColor: Colors.white.withValues(alpha: .38),
              textStyle: body(14, weight: FontWeight.w700)),
          child: Text(text)));
  Widget input(int index, String label,
          {String? hint,
          TextInputType? keyboard,
          int lines = 1,
          bool readOnly = false,
          VoidCallback? onTap}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 9),
            child: Text(label,
                style: body(12, alpha: .7, weight: FontWeight.w600))),
        TextField(
            controller: fields[index],
            onChanged: (_) => setState(() {}),
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboard,
            maxLines: lines,
            style: body(15, weight: FontWeight.w500),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: body(15, alpha: .38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .105),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: .15))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: .34))),
            )),
      ]);
  Widget profilePhoto(double size) => avatar?.isNotEmpty == true
      ? InitialsAvatar(initials: 'WP', imageUrl: avatar, size: size)
      : Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .08),
              border: Border.all(color: Colors.white.withValues(alpha: .18))),
          padding: EdgeInsets.all(size * .24),
          child: Image.asset('assets/images/onboarding_logo.png'));

  Widget form(bool short) {
    switch (step) {
      case 0:
        return Center(
            child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            profilePhoto(short ? 108 : 126),
            Positioned(
                right: -5,
                bottom: 8,
                child: SizedBox(
                    width: 31,
                    height: 31,
                    child: IconButton.filled(
                        onPressed: busy ? null : upload,
                        tooltip: 'Choose photo',
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xff151515)),
                        padding: EdgeInsets.zero,
                        icon: Icon(PhosphorIcons.plus(), size: 18))))
          ]),
          const SizedBox(height: 18),
          TextButton(
              onPressed: busy ? null : upload,
              child: Text(busy ? 'Uploading…' : 'Choose photo',
                  style: body(13, weight: FontWeight.w600))),
        ]));
      case 1:
        return input(1, 'Full name',
            hint: 'Enter your full name', keyboard: TextInputType.name);
      case 2:
        return input(2, 'Date of birth',
            hint: 'Select your date of birth', readOnly: true, onTap: () async {
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
        return input(3, 'Phone number',
            hint: '+234 801 234 5678', keyboard: TextInputType.phone);
      case 4:
        return input(4, 'Address',
            hint: 'Enter your address',
            keyboard: TextInputType.streetAddress,
            lines: 4);
      case 5:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          input(5, 'Occupation', hint: 'Enter your occupation'),
          const SizedBox(height: 12),
          Wrap(
              spacing: 6,
              runSpacing: 6,
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
                return FilterChip(
                    label: Text(value, style: body(11)),
                    selected: active,
                    selectedColor: const Color(0xff7439ab),
                    backgroundColor: Colors.white.withValues(alpha: .08),
                    onSelected: (select) => setState(() {
                          select ? parts.add(value) : parts.remove(value);
                          fields[5].text = parts.join(', ');
                        }));
              }).toList())
        ]);
      case 6:
        return Column(children: [
          input(6, 'Contact name',
              hint: 'Enter contact name', keyboard: TextInputType.name),
          const SizedBox(height: 18),
          input(7, 'Phone number',
              hint: '+234 801 234 5678', keyboard: TextInputType.phone)
        ]);
      case 7:
        return departments();
      default:
        return const SizedBox.shrink();
    }
  }

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
      TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          style: body(14),
          decoration: InputDecoration(
              hintText: 'Search departments',
              hintStyle: body(14, alpha: .38),
              prefixIcon:
                  Icon(PhosphorIcons.magnifyingGlass(), color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .105),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(18)))),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final d in linked)
          Chip(
              label: Text(
                  '${d['name']}${d['status'] == 'pending' ? ' · Pending' : ''}',
                  style: body(12)),
              backgroundColor: const Color(0xff7439ab)),
        for (final id in selected)
          InputChip(
              label: Text(
                  directory
                      .firstWhere((d) => d['department_id'] == id)['name']
                      .toString(),
                  style: body(12)),
              backgroundColor: const Color(0xff7439ab),
              deleteIconColor: Colors.white,
              onDeleted: () => setState(() => selected.remove(id))),
      ]),
      const SizedBox(height: 16),
      if (options.isEmpty)
        Text('No matching departments', style: body(13, alpha: .6)),
      LayoutBuilder(
          builder: (context, c) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options
                  .map((d) => SizedBox(
                      width: (c.maxWidth - 10) / 2,
                      child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: .15)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          onPressed: () => setState(
                              () => selected.add(d['department_id'] as String)),
                          child: Row(children: [
                            Expanded(
                                child: Text(d['name'].toString(),
                                    style: body(12))),
                            Icon(PhosphorIcons.plus(),
                                size: 16, color: Colors.white70)
                          ]))))
                  .toList())),
      const SizedBox(height: 10),
      Text('New departments are submitted for approval.',
          style: body(11, alpha: .6)),
    ]);
  }

  Widget background(int photo) => Stack(fit: StackFit.expand, children: [
        Transform.scale(
            scale: 1.07,
            child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Image.asset('assets/images/onboarding_$photo.jpg',
                    fit: BoxFit.cover))),
        ColoredBox(color: Colors.black.withValues(alpha: .42)),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
              Color(0x33000000),
              Color(0x5c000000),
              Color(0xad000000),
              Color(0xe6000000)
            ],
                    stops: [
              0,
              .35,
              .7,
              1
            ]))),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: RadialGradient(
                    center: Alignment(0, 1.24),
                    radius: .9,
                    colors: [Color(0x4d843fff), Colors.transparent]))),
      ]);
  Widget backButton() => IconButton.filledTonal(
      tooltip: step == 0 ? 'Back to sign in' : 'Back',
      onPressed: busy
          ? null
          : () {
              if (step == 0) {
                Supabase.instance.client.auth.signOut();
              } else {
                move(step - 1);
              }
            },
      style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .08),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: .14))),
      icon: Icon(PhosphorIcons.arrowLeft(), size: 20));
  @override
  Widget build(BuildContext context) {
    final side = math.max(24.0, (MediaQuery.sizeOf(context).width - 600) / 2);
    final short = MediaQuery.sizeOf(context).height <= 780;
    final photo = PrototypeAuthScope.of(context)?.photo ?? 0;
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !busy && step > 0 && step < 9) move(step - 1);
        },
        child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(fit: StackFit.expand, children: [
              if (step < 9) background(photo),
              if (step == 9)
                reward(short)
              else
                SafeArea(
                    child: loading
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : Column(children: [
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 18, 20, 3),
                                child: Row(children: [
                                  backButton(),
                                  const Spacer(),
                                  if (step < 8)
                                    TextButton(
                                        onPressed: busy
                                            ? null
                                            : () => advance(skip: true),
                                        child: Text('Skip', style: body(13)))
                                ])),
                            if (step < 8)
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: LinearProgressIndicator(
                                      value: (step + 1) / 8,
                                      minHeight: 3,
                                      color: Colors.white,
                                      backgroundColor: Colors.white24)),
                            Expanded(
                                child: LayoutBuilder(
                                    builder: (context, c) =>
                                        SingleChildScrollView(
                                            padding: EdgeInsets.fromLTRB(
                                                MediaQuery.sizeOf(context)
                                                            .width >=
                                                        600
                                                    ? side
                                                    : (short ? 24 : 28),
                                                step == 7
                                                    ? (short ? 24 : 38)
                                                    : (short ? 34 : 56),
                                                MediaQuery.sizeOf(context)
                                                            .width >=
                                                        600
                                                    ? side
                                                    : (short ? 24 : 28),
                                                20),
                                            child: AnimatedBuilder(
                                                animation: entrance,
                                                builder: (context, child) {
                                                  final t = ease.transform(
                                                      entrance.value);
                                                  return Opacity(
                                                      opacity: t,
                                                      child: Transform.translate(
                                                          offset: Offset(
                                                              (backwards
                                                                      ? -16
                                                                      : 16) *
                                                                  (1 - t),
                                                              0),
                                                          child: child));
                                                },
                                                child: step == 8
                                                    ? done(short)
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                            Text(
                                                                'Verify your details',
                                                                style: body(12,
                                                                        alpha:
                                                                            .58,
                                                                        weight: FontWeight
                                                                            .w600)
                                                                    .copyWith(
                                                                        height:
                                                                            1,
                                                                        letterSpacing:
                                                                            .18)),
                                                            const SizedBox(
                                                                height: 9),
                                                            ConstrainedBox(
                                                                constraints:
                                                                    const BoxConstraints(
                                                                        maxWidth:
                                                                            330),
                                                                child: Text(
                                                                    titles[
                                                                        step],
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: title(MediaQuery.sizeOf(context).width <=
                                                                            370
                                                                        ? 29
                                                                        : short
                                                                            ? 30
                                                                            : 34))),
                                                            const SizedBox(
                                                                height: 16),
                                                            Text(
                                                                descriptions[
                                                                    step],
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: body(
                                                                    short
                                                                        ? 13
                                                                        : 14,
                                                                    alpha:
                                                                        .68)),
                                                            SizedBox(
                                                                height: short
                                                                    ? 28
                                                                    : 42),
                                                            form(short),
                                                          ]))))),
                            if (error != null)
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
                                  child: Semantics(
                                      liveRegion: true,
                                      child: Text(error!,
                                          style: body(13),
                                          textAlign: TextAlign.center))),
                            Padding(
                                padding: EdgeInsets.fromLTRB(
                                    MediaQuery.sizeOf(context).width >= 600
                                        ? side
                                        : (short ? 24 : 28),
                                    8,
                                    MediaQuery.sizeOf(context).width >= 600
                                        ? side
                                        : (short ? 24 : 28),
                                    short ? 26 : 34),
                                child: action(
                                    busy
                                        ? 'Saving…'
                                        : step == 8
                                            ? 'Continue to WPCC Community'
                                            : 'Continue',
                                    busy
                                        ? null
                                        : step == 8
                                            ? openReward
                                            : valid
                                                ? () => advance()
                                                : null)),
                            if (error != null &&
                                avatar == null &&
                                fields[1].text.isEmpty)
                              TextButton(
                                  onPressed: load,
                                  child: const Text('Retry loading details')),
                          ])),
            ])));
  }

  Widget done(bool short) => Column(children: [
        SizedBox(height: short ? 14 : 40),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .1),
                          border: Border.all(color: Colors.white24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.white.withValues(alpha: .045),
                                spreadRadius: 12)
                          ]),
                      child: InitialsAvatar(
                          initials: 'WP', imageUrl: avatar, size: 92)),
                ]))),
        SizedBox(height: short ? 28 : 38),
        Text('All good', style: body(12, alpha: .58, weight: FontWeight.w600)),
        const SizedBox(height: 13),
        Text('Details Verified',
            textAlign: TextAlign.center, style: title(short ? 33 : 38)),
        const SizedBox(height: 16),
        Text(
            'Thank you for verifying your details. This helps us reach out and serve you better.',
            textAlign: TextAlign.center,
            style: body(14, alpha: .68)),
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
