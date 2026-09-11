import 'package:flutter/material.dart';

class WpccLogo extends StatelessWidget {
  const WpccLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * .28),
          boxShadow: const [BoxShadow(color: Color(0x0A35394A), blurRadius: 16, offset: Offset(0, 5))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Container(height: size * .40, decoration: BoxDecoration(color: const Color(0xFFD22E8A), borderRadius: BorderRadius.circular(size * .10)))),
            SizedBox(width: size * .06),
            Expanded(child: Container(height: size * .36, decoration: BoxDecoration(color: const Color(0xFF73B53C), borderRadius: BorderRadius.circular(size * .10)))),
          ],
        ),
      );
}
