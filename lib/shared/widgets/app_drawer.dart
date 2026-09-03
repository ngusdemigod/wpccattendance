import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/supabase_auth/auth_util.dart';
import '../../features/profile/profile_classes_screen.dart';
import '../../features/profile/profile_query_screen.dart';
import '../../flutter_flow/custom_icons.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  String get _fullName {
    final name = currentUserDisplayName.trim();
    return name.isNotEmpty && !name.contains('@') ? name : 'WPCC Worker';
  }

  String get _initials {
    final parts = _fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  void _select(BuildContext context, int index) {
    Navigator.pop(context);
    onSelected(index);
  }

  void _push(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _unavailable(BuildContext context, String label) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('$label is not available yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth =
        (MediaQuery.sizeOf(context).width * .94).clamp(0.0, 367.0);
    return Drawer(
      width: drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      backgroundColor: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 27),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0x14111827)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC98B49),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials,
                      style: _sans(14, FontWeight.w500, Colors.white),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _sans(
                            17,
                            FontWeight.w500,
                            const Color(0xFF13213A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Media & Communications · Lead',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _sans(
                            13,
                            FontWeight.w400,
                            const Color(0xFF758099),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    FFIcons.kcaretRight,
                    size: 21,
                    color: Color(0xFF13213A),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 21, 0, 10),
              child: Text(
                'MAIN',
                style: _sans(
                  13,
                  FontWeight.w500,
                  const Color(0xFF8C98AB),
                ).copyWith(letterSpacing: .8),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(15, 0, 9, 24),
                children: [
                  _NavRow(
                    icon: FFIcons.khouse,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => _select(context, 0),
                  ),
                  _NavRow(
                    icon: FFIcons.kcalendarCheck,
                    label: 'Events',
                    count: '2',
                    selected: currentIndex == 1,
                    onTap: () => _select(context, 1),
                  ),
                  _NavRow(
                    icon: FFIcons.kusersThree,
                    label: 'Department',
                    count: '4',
                    selected: currentIndex == 2,
                    onTap: () => _select(context, 2),
                  ),
                  _NavRow(
                    icon: FFIcons.kuserPlus,
                    label: 'Souls',
                    onTap: () => _unavailable(context, 'Souls'),
                  ),
                  _NavRow(
                    icon: FFIcons.kgraduationCap,
                    label: 'Classes',
                    count: '1',
                    onTap: () => _push(context, const ProfileClassesScreen()),
                  ),
                  _NavRow(
                    icon: FFIcons.kchatsCircle,
                    label: 'Counselling',
                    onTap: () => _unavailable(context, 'Counselling'),
                  ),
                  _NavRow(
                    icon: FFIcons.kquestion,
                    label: 'Query',
                    count: '3',
                    onTap: () => _push(context, const ProfileQueryScreen()),
                  ),
                  _NavRow(
                    icon: FFIcons.kbroadcast,
                    label: 'Media',
                    onTap: () => _unavailable(context, 'Media'),
                  ),
                  _NavRow(
                    icon: FFIcons.kwallet,
                    label: 'Accounts',
                    onTap: () => _unavailable(context, 'Accounts'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _sans(double size, FontWeight weight, Color color) {
    return GoogleFonts.instrumentSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF263650);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? const Color(0xFF17171A) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(icon, size: 22, color: foreground),
                const SizedBox(width: 17),
                Expanded(
                  child: Text(
                    label,
                    style: AppDrawer._sans(
                      14,
                      selected ? FontWeight.w500 : FontWeight.w400,
                      foreground,
                    ),
                  ),
                ),
                if (count != null)
                  Container(
                    width: 30,
                    height: 29,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count!,
                      style: AppDrawer._sans(
                        12,
                        FontWeight.w500,
                        const Color(0xFF263650),
                      ),
                    ),
                  ),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
