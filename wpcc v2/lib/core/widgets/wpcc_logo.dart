import 'package:flutter/material.dart';

class WpccLogo extends StatelessWidget {
  const WpccLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * .28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A35394A), blurRadius: 16, offset: Offset(0, 5))
          ],
        ),
        child: Image.asset(
          'assets/images/wpcc_logo.png',
          fit: BoxFit.contain,
          semanticLabel: 'WPCC church logo',
        ),
      );
}
