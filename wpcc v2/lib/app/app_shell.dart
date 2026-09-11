import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int indexFor(String location) {
    if (location.startsWith('/departments')) return 1;
    if (location.startsWith('/events')) return 2;
    if (location.startsWith('/give')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = indexFor(location);
    const destinations = [
      '/home',
      '/departments',
      '/events',
      '/give',
      '/profile'
    ];
    final icons = [
      PhosphorIcons.house(),
      PhosphorIcons.usersThree(),
      PhosphorIcons.calendarDots(),
      PhosphorIcons.handHeart(),
      PhosphorIcons.userCircle()
    ];
    final labels = ['Home', 'Department', 'Events', 'Give', 'Profile'];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .78),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .82)),
                  borderRadius: BorderRadius.circular(28)),
              child: Row(
                children: List.generate(
                    5,
                    (i) => Expanded(
                          child: Semantics(
                            button: true,
                            selected: selected == i,
                            label: labels[i],
                            child: InkWell(
                              onTap: () => context.go(destinations[i]),
                              child: SizedBox(
                                  height: 56,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          width: 32,
                                          height: 28,
                                          decoration: BoxDecoration(
                                              color: selected == i
                                                  ? WpccColors.ink
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Icon(icons[i],
                                              size: 18,
                                              color: selected == i
                                                  ? Colors.white
                                                  : WpccColors.muted),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(labels[i],
                                            maxLines: 1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                    fontSize: 12,
                                                    color: selected == i
                                                        ? WpccColors.ink
                                                        : WpccColors.muted)),
                                      ])),
                            ),
                          ),
                        )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
