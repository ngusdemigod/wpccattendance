import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../departments_models.dart';

/// Circular avatar: shows the profile picture when available and falls back
/// to initials on the shared member-avatar background otherwise.
class DepartmentAvatar extends StatelessWidget {
  const DepartmentAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 56,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: const Color(0xFFF3E8E5),
      child: Text(
        initialsFor(name),
        style: GoogleFonts.instrumentSans(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
}
