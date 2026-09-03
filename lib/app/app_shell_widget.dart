import 'package:flutter/material.dart';
import '../flutter_flow/custom_icons.dart';

import '../features/departments/departments_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/linked_flows/linked_flow_screens.dart';
import '../pages/EventsListing/events_listing_widget.dart';
import '../shared/widgets/app_drawer.dart';
import '../shared/widgets/hamburger_menu_button.dart';

class AppShellWidget extends StatefulWidget {
  const AppShellWidget({super.key});

  static const String routeName = 'AppShell';
  static const String routePath = '/app';

  @override
  State<AppShellWidget> createState() => _AppShellWidgetState();
}

class _AppShellWidgetState extends State<AppShellWidget> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
        onEventsTap: () => _onTabSelected(1),
        onDepartmentsTap: () => _onTabSelected(2),
        onProfileTap: () => _onTabSelected(3),
      ),
      const EventsListingWidget(),
      const DepartmentsScreen(),
      const ProfileScreen(),
      const GivingScreen(),
    ];
    return Scaffold(
      key: appShellScaffoldKey,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onSelected: _onTabSelected,
      ),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(13, 0, 13, 13),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: const Color(0x12000000)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem('Home', FFIcons.khouse, 0, _currentIndex, _onTabSelected),
              _NavItem('Teams', FFIcons.kusersThree, 2, _currentIndex, _onTabSelected),
              _NavItem('Events', FFIcons.kcalendarDots, 1, _currentIndex, _onTabSelected),
              _NavItem('Give', FFIcons.khandHeart, 4, _currentIndex, _onTabSelected),
              _NavItem('Profile', FFIcons.kuserCircle, 3, _currentIndex, _onTabSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.label, this.icon, this.index, this.current, this.onTap);
  final String label;
  final IconData icon;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(color: active ? const Color(0xFF303239) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 21, color: active ? Colors.white : const Color(0xFF555961)), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.white : const Color(0xFF555961)))]),
      ),
    );
  }
}
