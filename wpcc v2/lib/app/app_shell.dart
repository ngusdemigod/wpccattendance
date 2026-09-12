import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int indexFor(String location) {
    if (location.startsWith('/media')) return 1;
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
      '/media',
      '/events',
      '/give',
      '/profile'
    ];
    final icons = [
      PhosphorIcons.house(),
      PhosphorIcons.microphoneStage(),
      PhosphorIcons.calendarDots(),
      PhosphorIcons.handHeart(),
      PhosphorIcons.userCircle()
    ];
    final labels = ['Home', 'Media', 'Events', 'Give', 'Profile'];

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
                            excludeSemantics: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => context.go(destinations[i]),
                              child: Align(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 62,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: selected == i
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              WpccColors.primary,
                                              WpccColors.primaryDeep,
                                            ],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: selected == i
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x38683793),
                                              blurRadius: 22,
                                              offset: Offset(0, 10),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(icons[i],
                                            size: 18,
                                            color: selected == i
                                                ? Colors.white
                                                : WpccColors.muted),
                                        const SizedBox(height: 3),
                                        Text(labels[i],
                                            maxLines: 1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                    fontSize: 12,
                                                    color: selected == i
                                                        ? Colors.white
                                                        : WpccColors.muted)),
                                      ]),
                                ),
                              ),
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
