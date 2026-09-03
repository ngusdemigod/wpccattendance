import 'package:flutter/material.dart';

import '../../flutter_flow/custom_icons.dart';

final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();

/// Opens the app drawer on root screens and becomes a back button on pushed
/// inner pages.
class HamburgerMenuButton extends StatelessWidget {
  const HamburgerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isInnerPage = ModalRoute.of(context)?.isFirst == false;

    return Semantics(
      button: true,
      label: isInnerPage ? 'Go back' : 'Open navigation menu',
      child: SizedBox.square(
        dimension: 42,
        child: InkResponse(
          containedInkWell: false,
          highlightShape: BoxShape.circle,
          onTap: () {
            if (isInnerPage) {
              Navigator.of(context).maybePop();
              return;
            }

            final appShellState = appShellScaffoldKey.currentState;
            if (appShellState != null && appShellState.hasDrawer) {
              appShellState.openDrawer();
              return;
            }
            Scaffold.maybeOf(context)?.openDrawer();
          },
          child: Icon(
            isInnerPage ? FFIcons.karrowLeft : FFIcons.kmenuLineHorizontal,
            size: 20,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}
