import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(
      {super.key, required this.initials, this.size = 40, this.imageUrl});

  final String initials;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final fallback = _fallback(context);
    final child = hasImage
        ? ClipOval(
            child: imageUrl!.startsWith('r2://')
                ? _PrivateR2Avatar(
                    storedUrl: imageUrl!,
                    size: size,
                    fallback: fallback,
                  )
                : Image.network(
                    imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                  ),
          )
        : fallback;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8EAF0), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A31374E), blurRadius: 22, offset: Offset(0, 10))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _fallback(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [WpccColors.lavender, WpccColors.coolBlue, WpccColors.warm],
            stops: [0, .55, 1],
            transform: GradientRotation(2.530727),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: size * .25,
                      letterSpacing: -.4,
                    ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-.4, -.52),
                    radius: .72,
                    colors: [
                      Colors.white.withValues(alpha: .44),
                      Colors.transparent
                    ],
                    stops: const [0, .55],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _PrivateR2Avatar extends StatefulWidget {
  const _PrivateR2Avatar({
    required this.storedUrl,
    required this.size,
    required this.fallback,
  });
  final String storedUrl;
  final double size;
  final Widget fallback;

  @override
  State<_PrivateR2Avatar> createState() => _PrivateR2AvatarState();
}

class _PrivateR2AvatarState extends State<_PrivateR2Avatar> {
  static final cache = <String, ({Uint8List bytes, DateTime expiresAt})>{};
  late Future<Uint8List> resolvedBytes;

  @override
  void initState() {
    super.initState();
    resolvedBytes = _resolve();
  }

  @override
  void didUpdateWidget(covariant _PrivateR2Avatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedUrl != widget.storedUrl) resolvedBytes = _resolve();
  }

  Future<Uint8List> _resolve() async {
    final cached = cache[widget.storedUrl];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.bytes;
    }
    final response = await Supabase.instance.client.functions.invoke(
      'profile-avatar',
      body: {'avatar_url': widget.storedUrl, 'include_data': true},
    );
    if (response.status >= 400 || response.data is! Map) {
      throw StateError('Avatar unavailable');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    final encoded = data['data_base64']?.toString() ?? '';
    if (encoded.isEmpty) throw StateError('Avatar unavailable');
    final bytes = base64Decode(encoded);
    cache[widget.storedUrl] = (
      bytes: bytes,
      expiresAt: DateTime.now().add(const Duration(minutes: 4)),
    );
    return bytes;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
        future: resolvedBytes,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) return widget.fallback;
          return Image.memory(
            bytes,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => widget.fallback,
          );
        },
      );
}
