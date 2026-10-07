import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import 'media_motion.dart';
import 'media_repository.dart';
import 'media_save.dart';

typedef PhotoFileLoader = Future<Uint8List> Function(String photoId);
typedef FileSaver = Future<SaveOutcome> Function(Uint8List bytes,
    {required String filename, required String mime});

enum _Phase { idle, busy, done }

/// Round download button for a photo. It sits in the top right corner of the
/// image: a 36px dark disc inside a 48px touch target. Tapping gives instant
/// feedback (a spinner), then a check, then returns to the icon.
class MediaDownloadButton extends StatefulWidget {
  const MediaDownloadButton(
      {super.key, required this.photo, this.loadFile, this.save});
  final Map<String, dynamic> photo;
  final PhotoFileLoader? loadFile;
  final FileSaver? save;

  @override
  State<MediaDownloadButton> createState() => _MediaDownloadButtonState();
}

class _MediaDownloadButtonState extends State<MediaDownloadButton> {
  _Phase phase = _Phase.idle;

  String get _id => widget.photo['id']?.toString() ?? '';

  Future<void> _download() async {
    if (phase == _Phase.busy || _id.isEmpty) return;
    setState(() => phase = _Phase.busy);
    try {
      final bytes = await (widget.loadFile ?? MediaRepository().photoFile)(_id);
      final outcome = await (widget.save ?? saveMediaBytes)(bytes,
          filename: 'wpcc-photo-$_id.webp', mime: 'image/webp');
      if (!mounted) return;
      // Closing the save dialog or share sheet is not a failure.
      if (outcome == SaveOutcome.cancelled) {
        setState(() => phase = _Phase.idle);
        return;
      }
      setState(() => phase = _Phase.done);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) setState(() => phase = _Phase.idle);
    } catch (_) {
      if (!mounted) return;
      setState(() => phase = _Phase.idle);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Could not download this photo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (phase) {
      _Phase.idle => 'Download photo',
      _Phase.busy => 'Downloading photo',
      _Phase.done => 'Photo downloaded',
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: _download,
      child: Tooltip(
        message: 'Download photo',
        child: AppPressMotion(
          child: InkResponse(
            radius: 24,
            onTap: _download,
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0x8C000000)),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Center(
                      child: MediaSwap(
                        child: switch (phase) {
                          _Phase.idle => const Icon(
                              PhosphorIconsRegular.downloadSimple,
                              key: ValueKey('idle'),
                              size: 18,
                              color: Colors.white),
                          _Phase.busy => const SizedBox.square(
                              key: ValueKey('busy'),
                              dimension: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)),
                          _Phase.done => const Icon(PhosphorIconsRegular.check,
                              key: ValueKey('done'),
                              size: 18,
                              color: Colors.white),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
