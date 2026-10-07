import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_sheet.dart';

const searchSections = [
  ('All', PhosphorIconsRegular.magnifyingGlass),
  ('Events', PhosphorIconsRegular.calendarBlank),
  ('Departments', PhosphorIconsRegular.users),
  ('Announcements', PhosphorIconsRegular.chatCircle),
  ('Media', PhosphorIconsRegular.playCircle),
  ('Audio', PhosphorIconsRegular.headphones),
  ('Devotional', PhosphorIconsRegular.bookOpen),
  ('Classes', PhosphorIconsRegular.graduationCap),
  ('People', PhosphorIconsRegular.user),
];

/// Result `section` keys, in the order their groups are shown, with the label
/// used by [searchSections] and the filter sheet.
const searchSectionKeys = [
  ('events', 'Events'),
  ('departments', 'Departments'),
  ('announcements', 'Announcements'),
  ('media', 'Media'),
  ('audio', 'Audio'),
  ('devotional', 'Devotional'),
  ('classes', 'Classes'),
  ('people', 'People'),
];

/// Label for a result `section` key, or 'All' when the key is unknown.
String searchSectionLabel(String key) {
  for (final entry in searchSectionKeys) {
    if (entry.$1 == key) return entry.$2;
  }
  return 'All';
}

bool isSearchSection(String? label) =>
    label != null && searchSections.any((section) => section.$1 == label);

class MemberSearchScope extends StatefulWidget {
  const MemberSearchScope({super.key, required this.child});
  final Widget child;

  static ValueNotifier<String>? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<_MemberSearchSelection>()
      ?.selection;

  @override
  State<MemberSearchScope> createState() => _MemberSearchScopeState();
}

class _MemberSearchScopeState extends State<MemberSearchScope> {
  final selection = ValueNotifier<String>('All');

  @override
  void dispose() {
    selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _MemberSearchSelection(selection: selection, child: widget.child);
}

class _MemberSearchSelection extends InheritedWidget {
  const _MemberSearchSelection({required this.selection, required super.child});
  final ValueNotifier<String> selection;

  @override
  bool updateShouldNotify(_MemberSearchSelection oldWidget) => false;
}

Future<String?> showSearchFilterSheet(BuildContext context,
        {String selected = 'All'}) =>
    showMemberSheet<String>(
      context: context,
      title: 'Search filters',
      builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
        for (final section in searchSections)
          Padding(
            padding:
                EdgeInsets.only(bottom: section == searchSections.last ? 0 : 7),
            child: MemberListRow(
              title: section.$1,
              selected: selected == section.$1,
              trailing: selected == section.$1
                  ? Icon(PhosphorIconsRegular.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)
                  : const SizedBox.shrink(),
              onTap: () => Navigator.of(context).pop(section.$1),
            ),
          ),
      ]),
    );
