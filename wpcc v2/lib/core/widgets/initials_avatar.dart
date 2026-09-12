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
    final child = imageUrl != null && imageUrl!.isNotEmpty
        ? ClipOval(
            child: imageUrl!.startsWith('r2://')
                ? _PrivateR2Avatar(
                    storedUrl: imageUrl!,
                    size: size,
                    fallback: _initials(context),
                  )
                : Image.network(
                    imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials(context),
                  ),
          )
        : _initials(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8EAF0), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WpccColors.lavender, WpccColors.coolBlue, WpccColors.warm],
          stops: [0, .55, 1],
          transform: GradientRotation(2.530727),
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A31374E), blurRadius: 22, offset: Offset(0, 10))
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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

  Widget _initials(BuildContext context) => Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: size * .25,
                letterSpacing: -.4,
              ),
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
  static final cache = <String, ({String url, DateTime expiresAt})>{};
  late Future<String> resolvedUrl;

  @override
  void initState() {
    super.initState();
    resolvedUrl = _resolve();
  }

  @override
  void didUpdateWidget(covariant _PrivateR2Avatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedUrl != widget.storedUrl) resolvedUrl = _resolve();
  }

  Future<String> _resolve() async {
    final cached = cache[widget.storedUrl];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.url;
    }
    final response = await Supabase.instance.client.functions.invoke(
      'profile-avatar',
      body: {'avatar_url': widget.storedUrl},
    );
    if (response.status >= 400 || response.data is! Map) {
      throw StateError('Avatar unavailable');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    final url = data['url']?.toString() ?? '';
    if (url.isEmpty) throw StateError('Avatar unavailable');
    cache[widget.storedUrl] = (
      url: url,
      expiresAt: DateTime.now().add(const Duration(minutes: 4)),
    );
    return url;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: resolvedUrl,
        builder: (context, snapshot) {
          final url = snapshot.data;
          if (url == null) return widget.fallback;
          return Image.network(
            url,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => widget.fallback,
          );
        },
      );
}
