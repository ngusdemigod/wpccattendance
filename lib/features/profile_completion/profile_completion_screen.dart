import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/app_shell_widget.dart';
import '../../auth/supabase_auth/auth_util.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../flutter_flow/upload_data.dart';
import '../../shared/widgets/wpcc_shimmer.dart';
import '../../shared/widgets/fade_slide_switcher.dart';
import 'profile_completion_controller.dart';
import 'profile_completion_models.dart';
import 'profile_completion_service.dart';
import 'setup_widgets.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  static const String routeName = 'ProfileCompletionSetup';
  static const String routePath = '/profile-completion';

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  late final ProfileCompletionController _controller;
  bool _isPrimaryActionBusy = false;

  @override
  void initState() {
    super.initState();
    _controller = ProfileCompletionController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      imageQuality: 85,
      allowPhoto: true,
      pickerFontFamily: 'Plus Jakarta Sans',
    );

    if (selectedMedia == null || selectedMedia.isEmpty) {
      return;
    }

    if (!selectedMedia
        .every((media) => validateFileFormat(media.storagePath, context))) {
      return;
    }

    final bytes = selectedMedia.first.bytes;
    if (bytes.isEmpty) {
      return;
    }

    _controller.setAvatar(Uint8List.fromList(bytes));
  }

  void _proceedToApp() {
    GoRouter.of(context)
        .appState
        .setProfileCompletionStatus(ProfileCompletionStatus.complete);

    // When opened as an overlay above the app shell (the normal path from the
    // home screen), pop it so it fades back down onto home. Fall back to a
    // shell navigation if this screen was reached as a standalone route.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.goNamedAuth(
        AppShellWidget.routeName,
        mounted,
        ignoreRedirect: true,
      );
    }
  }

  Future<void> _handlePrimaryAction() async {
    switch (_controller.step) {
      case SetupFlowStep.greeting:
        _controller.continueFromGreeting();
        break;
      case SetupFlowStep.uploadPrompt:
        await _pickImage();
        break;
      case SetupFlowStep.uploadPreview:
        if (_controller.hasPendingRequirements) {
          _controller.continueFromPreview();
        } else {
          await _submitProfileCompletion();
        }
        break;
      case SetupFlowStep.form:
        await _submitProfileCompletion();
        break;
      case SetupFlowStep.success:
        _proceedToApp();
        break;
    }
  }

  Future<void> _submitProfileCompletion() async {
    if (_isPrimaryActionBusy) {
      return;
    }

    setState(() {
      _isPrimaryActionBusy = true;
    });

    try {
      final saved = await _controller.submit(
        processedAvatarBytes: await _buildProcessedAvatarBytes(),
      );
      if (saved && mounted) {
        GoRouter.of(context)
            .appState
            .setProfileCompletionStatus(ProfileCompletionStatus.complete);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrimaryActionBusy = false;
        });
      }
    }
  }

  bool _canGoBack(SetupFlowStep step) => _controller.canGoBack();

  Future<Uint8List?> _buildProcessedAvatarBytes() async {
    final sourceBytes = _controller.avatarBytes;
    if (sourceBytes == null || sourceBytes.isEmpty) {
      return null;
    }

    const outputSize = 512.0;
    const previewDiameter = 118.0;
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(
      BoxFit.cover,
      imageSize,
      const Size(outputSize, outputSize),
    );
    final destinationSize = Size(
      fitted.destination.width * _controller.avatarScale,
      fitted.destination.height * _controller.avatarScale,
    );
    final destinationRect = Rect.fromCenter(
      center: Offset(
        outputSize / 2 +
            (_controller.avatarOffset.dx * (outputSize / previewDiameter)),
        outputSize / 2 +
            (_controller.avatarOffset.dy * (outputSize / previewDiameter)),
      ),
      width: destinationSize.width,
      height: destinationSize.height,
    );

    canvas.drawImageRect(
      image,
      Offset.zero & imageSize,
      destinationRect,
      paint,
    );

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(
      outputSize.toInt(),
      outputSize.toInt(),
    );
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List() ?? sourceBytes;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const _ProfileCompletionLoadingView();
        }

        return SetupScaffold(
          header: SetupHeader(
            label: _headerLabel(_controller.step),
            onBack: _canGoBack(_controller.step) ? _controller.goBack : null,
          ),
          body: FadeSlideSwitcher(
            child: _StepBody(
              key: ValueKey(_controller.step),
              controller: _controller,
              onChangeImage: _pickImage,
            ),
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.submitError != null) ...[
                _SetupMotion(
                  key: ValueKey('error-${_controller.step.name}'),
                  offsetY: 0.02,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _controller.submitError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD92D20),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
              _SetupMotion(
                key: ValueKey('button-${_controller.step.name}'),
                delay: const Duration(milliseconds: 120),
                offsetY: 0.025,
                child: PrimarySetupButton(
                  label: _buttonLabel(_controller.step),
                  leadingIcon: _controller.step == SetupFlowStep.uploadPrompt
                      ? Icons.upload_rounded
                      : null,
                  isPink: _controller.step == SetupFlowStep.success,
                  isLoading: _controller.isSaving || _isPrimaryActionBusy,
                  onPressed: _handlePrimaryAction,
                ),
              ),
              const SizedBox(height: 14),
              const _SetupMotion(
                key: ValueKey('security-footer'),
                delay: Duration(milliseconds: 180),
                offsetY: 0.02,
                child: SecurityFooter(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _headerLabel(SetupFlowStep step) {
    switch (step) {
      case SetupFlowStep.greeting:
        return 'Complete profile';
      case SetupFlowStep.uploadPrompt:
      case SetupFlowStep.uploadPreview:
        return 'Step 1 of ${_controller.totalProgressSteps}';
      case SetupFlowStep.form:
        return 'Step ${_controller.activeProgressIndex + 1} of ${_controller.totalProgressSteps}';
      case SetupFlowStep.success:
        return 'Setup complete';
    }
  }

  String _buttonLabel(SetupFlowStep step) {
    switch (step) {
      case SetupFlowStep.greeting:
        return 'Next';
      case SetupFlowStep.uploadPrompt:
        return 'Upload image';
      case SetupFlowStep.uploadPreview:
        return _controller.hasPendingRequirements ? 'Continue' : 'Done';
      case SetupFlowStep.form:
        return _controller.isLastRequirement ? 'Done' : 'Continue';
      case SetupFlowStep.success:
        return 'Proceed';
    }
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    super.key,
    required this.controller,
    required this.onChangeImage,
  });

  final ProfileCompletionController controller;
  final Future<void> Function() onChangeImage;

  String get _greetingName {
    final displayName = currentUserDisplayName.trim();
    if (displayName.isNotEmpty && !displayName.contains('@')) {
      return displayName.split(RegExp(r'\s+')).first;
    }

    return controller.firstName;
  }

  @override
  Widget build(BuildContext context) {
    switch (controller.step) {
      case SetupFlowStep.greeting:
        return _CenteredSetupContent(
          title: _greetingName.isEmpty ? 'Hello' : 'Hello $_greetingName',
          copy:
              'Let’s get to know you. There’s some missing information on your profile.',
        );
      case SetupFlowStep.uploadPrompt:
        return const _CenteredSetupContent(
          hero: UploadIconRing(),
          title: 'Upload a profile image',
          copy: 'Let members easily recognize you.',
          progressIndex: 0,
        );
      case SetupFlowStep.uploadPreview:
        return _CenteredSetupContent(
          hero: ProfileImagePreview(
            avatarBytes: controller.avatarBytes,
            legacyAvatarUrl: controller.legacyAvatarUrl,
            initials: controller.initials,
            onChangeImage: onChangeImage,
            scale: controller.avatarScale,
            offset: controller.avatarOffset,
            onTransformChanged: (transform) {
              controller.updateAvatarTransform(
                scale: transform.scale,
                offset: transform.offset,
              );
            },
          ),
          title: 'Looks good',
          copy:
              'Make sure your face is visible so members can identify you quickly.',
          progressIndex: 0,
          totalProgress: controller.totalProgressSteps,
        );
      case SetupFlowStep.form:
        return _RequirementStep(
          controller: controller,
        );
      case SetupFlowStep.success:
        return const _CenteredSetupContent(
          hero: SuccessCheck(),
          title: 'You\'re set to go',
          copy:
              'Your worker profile has been updated successfully. You can now continue into the WPCC app.',
          isSuccess: true,
        );
    }
  }
}

class _CenteredSetupContent extends StatelessWidget {
  const _CenteredSetupContent({
    this.hero,
    required this.title,
    required this.copy,
    this.progressIndex,
    this.totalProgress = 3,
    this.form,
    this.isSuccess = false,
  });

  final Widget? hero;
  final String title;
  final String copy;
  final int? progressIndex;
  final int totalProgress;
  final Widget? form;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hero != null)
          _SetupMotion(
            key: ValueKey('hero-$title'),
            delay: const Duration(milliseconds: 30),
            child: hero!,
          ),
        SizedBox(height: isSuccess ? 34 : 28),
        _SetupMotion(
          key: ValueKey('title-$title'),
          delay: const Duration(milliseconds: 90),
          child: SetupTitle(text: title, isSuccess: isSuccess),
        ),
        const SizedBox(height: 12),
        _SetupMotion(
          key: ValueKey('copy-$title'),
          delay: const Duration(milliseconds: 140),
          offsetY: 0.03,
          child: SetupCopy(text: copy),
        ),
        if (form != null) ...[
          const SizedBox(height: 34),
          _SetupMotion(
            key: ValueKey('form-$title'),
            delay: const Duration(milliseconds: 190),
            offsetY: 0.035,
            child: form!,
          ),
        ],
        if (progressIndex != null) ...[
          const SizedBox(height: 24),
          _SetupMotion(
            key: ValueKey('progress-$title'),
            delay: const Duration(milliseconds: 240),
            offsetY: 0.025,
            child: ProgressDots(
              activeIndex: progressIndex!,
              total: totalProgress,
            ),
          ),
        ],
      ],
    );
  }
}

class _RequirementStep extends StatelessWidget {
  const _RequirementStep({
    required this.controller,
  });

  final ProfileCompletionController controller;

  @override
  Widget build(BuildContext context) {
    final requirement = controller.currentRequirement!;
    return _CenteredSetupContent(
      hero: _FieldIconBadge(icon: requirement.icon),
      title: requirement.title,
      copy: requirement.copy,
      progressIndex: controller.activeProgressIndex,
      totalProgress: controller.totalProgressSteps,
      form: _buildField(context, requirement),
    );
  }

  Widget _buildField(
    BuildContext context,
    ProfileCompletionRequirement requirement,
  ) {
    switch (requirement.inputType) {
      case ProfileCompletionInputType.text:
        return SetupTextField(
          label: requirement.label,
          controller: controller.fieldController,
          helper: requirement.helper,
          hintText: requirement.hintText,
          errorText: controller.fieldError,
          onChanged: controller.onFieldChanged,
        );
      case ProfileCompletionInputType.multiline:
        return SetupTextArea(
          label: requirement.label,
          controller: controller.fieldController,
          helper: requirement.helper,
          hintText: requirement.hintText,
          errorText: controller.fieldError,
          onChanged: controller.onFieldChanged,
        );
      case ProfileCompletionInputType.phone:
        return SetupTextField(
          label: requirement.label,
          controller: controller.fieldController,
          keyboardType: TextInputType.phone,
          helper: requirement.helper,
          hintText: requirement.hintText,
          errorText: controller.fieldError,
          onChanged: controller.onFieldChanged,
        );
      case ProfileCompletionInputType.date:
        return SetupPickerField(
          label: requirement.label,
          value: _formatDate(controller.dateValue(requirement.field)),
          helper: requirement.helper,
          hintText: requirement.hintText,
          errorText: controller.fieldError,
          trailingIcon: Icons.calendar_today_outlined,
          onTap: () async {
            final now = DateTime.now();
            final existing = controller.dateValue(requirement.field);
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  existing ?? DateTime(now.year - 18, now.month, now.day),
              firstDate: DateTime(1950),
              lastDate: now,
            );
            if (picked != null) {
              controller.selectDate(picked);
            }
          },
        );
      case ProfileCompletionInputType.select:
        return SetupPickerField(
          label: requirement.label,
          value: controller.textValue(requirement.field),
          helper: requirement.helper,
          hintText: requirement.hintText,
          errorText: controller.fieldError,
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (sheetContext) {
                return SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      Text(
                        requirement.label,
                        style: const TextStyle(
                          fontFamily: 'Instrument Serif',
                          fontSize: 28,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...requirement.options.map(
                        (option) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            option,
                            style: const TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 15,
                              color: Color(0xFF111827),
                            ),
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(option),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
            if (selected != null) {
              controller.selectOption(selected);
            }
          },
        );
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _FieldIconBadge extends StatelessWidget {
  const _FieldIconBadge({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: const BoxDecoration(
        color: Color(0xFFF1EADD),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 38,
        color: const Color(0xFF111113),
      ),
    );
  }
}

class _SetupMotion extends StatefulWidget {
  const _SetupMotion({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 0.04,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<_SetupMotion> createState() => _SetupMotionState();
}

class _SetupMotionState extends State<_SetupMotion> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.delay > Duration.zero) {
        await Future<void>.delayed(widget.delay);
      }
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : Offset(0, widget.offsetY),
        child: widget.child,
      ),
    );
  }
}

class _ProfileCompletionLoadingView extends StatelessWidget {
  const _ProfileCompletionLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WpccShimmerBlock(width: 74, height: 10, radius: 8),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WpccShimmerCircle(size: 112),
                      SizedBox(height: 30),
                      WpccShimmerBlock(width: 210, height: 28, radius: 14),
                      SizedBox(height: 12),
                      WpccShimmerBlock(width: 250, height: 14, radius: 8),
                      SizedBox(height: 8),
                      WpccShimmerBlock(width: 220, height: 14, radius: 8),
                    ],
                  ),
                ),
              ),
              WpccShimmerCard(
                radius: 999,
                padding: EdgeInsets.zero,
                height: 54,
                child: SizedBox.expand(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
