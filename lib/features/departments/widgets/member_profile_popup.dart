import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../departments_models.dart';
import 'department_avatar.dart';

/// Public profile popup shown when a department member is tapped.
Future<void> showMemberProfilePopup(
  BuildContext context, {
  required DepartmentMember member,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x85111827),
    builder: (dialogContext) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: _MemberProfileCard(
          member: member,
        ),
      ),
    ),
  );
}

class _MemberProfileCard extends StatelessWidget {
  const _MemberProfileCard({
    required this.member,
  });

  final DepartmentMember member;

  String get _memberSinceLabel {
    final date = member.memberSince;
    if (date == null) {
      return '—';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFBF9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x14111827)),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFF111827)),
              ),
            ),
          ),
          DepartmentAvatar(
            name: member.fullName,
            avatarUrl: member.avatarUrl,
            size: 76,
          ),
          const SizedBox(height: 12),
          Text(
            member.fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF111827),
              height: 1.1,
              letterSpacing: -0.4,
            ),
          ),
          if (member.verified) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 11, color: Color(0xFF1A6B35)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Verified Worker',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFBF9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x14111827)),
            ),
            child: Column(
              children: [
                _infoRow('Role', member.roleTitle ?? 'Member'),
                _divider(),
                _infoRow('Department', member.departmentName ?? '—'),
                _divider(),
                _infoRow('Branch', member.branchName ?? '—'),
                _divider(),
                _infoRow('Member since', _memberSinceLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0x0F111827));
}
